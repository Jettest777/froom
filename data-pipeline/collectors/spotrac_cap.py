"""
Spotrac cap-hit scraper.

Pulls cap hit, dead money, and top-paid roster info per team from
https://www.spotrac.com/nfl/{team-slug}/cap/

Output: data-pipeline/output/cap-{season}.json
The iOS app consumes this via the same FeedClient pattern.

Spotrac may change their markup without notice; this collector is best-effort
and degrades gracefully on missing fields.
"""

from __future__ import annotations

import json
import re
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

import requests
import yaml
from bs4 import BeautifulSoup

# 32 team slugs as used in Spotrac URLs
TEAM_SLUGS = {
    "ARI": "arizona-cardinals",
    "ATL": "atlanta-falcons",
    "BAL": "baltimore-ravens",
    "BUF": "buffalo-bills",
    "CAR": "carolina-panthers",
    "CHI": "chicago-bears",
    "CIN": "cincinnati-bengals",
    "CLE": "cleveland-browns",
    "DAL": "dallas-cowboys",
    "DEN": "denver-broncos",
    "DET": "detroit-lions",
    "GB":  "green-bay-packers",
    "HOU": "houston-texans",
    "IND": "indianapolis-colts",
    "JAX": "jacksonville-jaguars",
    "KC":  "kansas-city-chiefs",
    "LV":  "las-vegas-raiders",
    "LAC": "los-angeles-chargers",
    "LAR": "los-angeles-rams",
    "MIA": "miami-dolphins",
    "MIN": "minnesota-vikings",
    "NE":  "new-england-patriots",
    "NO":  "new-orleans-saints",
    "NYG": "new-york-giants",
    "NYJ": "new-york-jets",
    "PHI": "philadelphia-eagles",
    "PIT": "pittsburgh-steelers",
    "SF":  "san-francisco-49ers",
    "SEA": "seattle-seahawks",
    "TB":  "tampa-bay-buccaneers",
    "TEN": "tennessee-titans",
    "WAS": "washington-commanders",
}

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 "
        "(KHTML, like Gecko) Version/17.0 Safari/605.1.15 "
        "(f/Room personal study tool)"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}


@dataclass
class PlayerCapHit:
    teamId: str
    season: int
    playerName: str
    position: str
    jerseyNumber: Optional[int]
    capHit: float
    baseSalary: Optional[float]
    signingBonusProration: Optional[float]
    restructureBonus: Optional[float]
    roster: str
    isDeadMoney: bool
    isTopHeavy: bool


@dataclass
class TeamCapSummary:
    teamId: str
    season: int
    salaryCap: float
    totalCapSpent: float
    activeContracts: int
    deadCap: float
    capSpace: float
    topCapHits: list
    updatedAt: str


def _money_to_float(text: str) -> float:
    """Convert '$45,123,456' or '$45.1M' to 45.12 (in millions)."""
    if not text:
        return 0.0
    t = text.replace(",", "").replace("$", "").strip()
    if t.upper().endswith("M"):
        try:
            return float(t[:-1])
        except ValueError:
            return 0.0
    try:
        n = float(t)
        return n / 1_000_000.0 if n > 1000 else n
    except ValueError:
        return 0.0


def fetch_team_cap(team_abbrev: str, season: int) -> Optional[TeamCapSummary]:
    slug = TEAM_SLUGS.get(team_abbrev)
    if not slug:
        return None
    url = f"https://www.spotrac.com/nfl/{slug}/cap/_/year/{season}"

    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
    except Exception as e:
        print(f"[spotrac] fetch failed for {team_abbrev}: {e}")
        return None

    soup = BeautifulSoup(r.text, "lxml")

    # Spotrac displays cap summary in a top "snapshot" table and then per-player rows.
    # This is a best-effort extraction; selectors may need tweaking as the site evolves.

    salary_cap = 0.0
    total_spent = 0.0
    dead_cap = 0.0
    cap_space = 0.0
    active_contracts = 0

    # Cap summary scorecards
    for card in soup.select(".scorecard, .info-card"):
        label_el = card.find(["span", "div"], class_=re.compile(r"label", re.I))
        value_el = card.find(["span", "div"], class_=re.compile(r"value", re.I))
        if not label_el or not value_el:
            continue
        label = label_el.get_text(strip=True).lower()
        value = _money_to_float(value_el.get_text(strip=True))
        if "salary cap" in label or "cap limit" in label:
            salary_cap = value
        elif "cap spending" in label or "total cap" in label:
            total_spent = value
        elif "dead" in label:
            dead_cap = value
        elif "cap space" in label or "cap room" in label:
            cap_space = value
        elif "active contract" in label:
            try:
                active_contracts = int(re.sub(r"\D", "", value_el.get_text()))
            except ValueError:
                active_contracts = 0

    # Player rows
    players: list[PlayerCapHit] = []
    table = soup.find("table", id=re.compile(r"player-cap|cap-table", re.I))
    if table is None:
        # Fallback: any table that looks like the active roster cap table
        table = soup.find("table")

    if table is not None:
        for row in table.find_all("tr"):
            cells = [c.get_text(strip=True) for c in row.find_all("td")]
            if len(cells) < 4:
                continue
            # Heuristic mapping: (name, pos, cap-hit, ...maybe more)
            name = cells[0]
            pos = cells[1] if len(cells) > 1 else "—"
            cap_hit = _money_to_float(cells[2] if len(cells) > 2 else "0")
            if not name or cap_hit <= 0:
                continue
            is_dead = "dead" in row.get_text(" ").lower()
            players.append(PlayerCapHit(
                teamId=team_abbrev,
                season=season,
                playerName=name,
                position=pos,
                jerseyNumber=None,
                capHit=cap_hit,
                baseSalary=None,
                signingBonusProration=None,
                restructureBonus=None,
                roster="released" if is_dead else "active",
                isDeadMoney=is_dead,
                isTopHeavy=False,
            ))

    # Sort and tag top-5 active as top-heavy
    players.sort(key=lambda p: p.capHit, reverse=True)
    for i, p in enumerate(players):
        if i < 5 and not p.isDeadMoney:
            players[i].isTopHeavy = True

    if total_spent == 0.0 and players:
        total_spent = sum(p.capHit for p in players if not p.isDeadMoney)
    if dead_cap == 0.0:
        dead_cap = sum(p.capHit for p in players if p.isDeadMoney)

    return TeamCapSummary(
        teamId=team_abbrev,
        season=season,
        salaryCap=salary_cap or 255.4,  # 2025 cap fallback
        totalCapSpent=total_spent,
        activeContracts=active_contracts or sum(1 for p in players if not p.isDeadMoney),
        deadCap=dead_cap,
        capSpace=cap_space if cap_space > 0 else max(0, (salary_cap or 255.4) - total_spent),
        topCapHits=[asdict(p) for p in players[:50]],
        updatedAt=datetime.now(timezone.utc).isoformat(),
    )


def run_all(season: int, out_dir: Path, polite_delay: float = 1.0) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    all_teams = {}
    for abbrev in TEAM_SLUGS.keys():
        print(f"[spotrac] fetching {abbrev}...")
        summary = fetch_team_cap(abbrev, season)
        if summary:
            all_teams[abbrev] = asdict(summary)
        time.sleep(polite_delay)

    out = {
        "version": 1,
        "season": season,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "teams": all_teams,
    }
    out_path = out_dir / f"cap-{season}.json"
    with open(out_path, "w") as f:
        json.dump(out, f, ensure_ascii=False, indent=2)
    print(f"[spotrac] wrote {out_path}")


if __name__ == "__main__":
    import argparse
    p = argparse.ArgumentParser()
    p.add_argument("--season", type=int, default=datetime.now(timezone.utc).year)
    p.add_argument("--out", default="output")
    p.add_argument("--config", default="config.yml")
    args = p.parse_args()
    run_all(args.season, Path(args.out))
