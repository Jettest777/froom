"""
Roster collector — authoritative, fact-based NFL rosters.

Primary source: nflverse (NFL official-derived data, free, no key).
  https://github.com/nflverse/nflverse-data/releases/download/rosters/roster_{season}.csv

The nflverse roster carries the columns we care about:
  season, team, position, depth_chart_position, jersey_number, status,
  full_name, first_name, last_name, height, weight, college, years_exp,
  espn_id, gsis_id, ...

We:
  1. Download the current season roster CSV (fall back to previous season if the
     current one isn't published yet — happens early in the league year).
  2. Keep only ACTIVE / on-roster players (status in the allowed set).
  3. Normalise team codes to the app's convention (e.g. nflverse uses LA -> LAR).
  4. Emit a compact JSON keyed by team abbreviation.

Output schema (rosters-latest.json):

{
  "version": 1,
  "generated_at": ISO,
  "season": 2025,
  "source": "nflverse",
  "teams": {
    "KC": [
      {"first":"Patrick","last":"Mahomes","pos":"QB","jersey":15,
       "height":"6-2","weight":225,"college":"Texas Tech","years":8,
       "status":"ACT","starter":true,"espn_id":"3139477"}
    ],
    ...
  }
}
"""

from __future__ import annotations

import argparse
import csv
import io
import json
from datetime import datetime, timezone
from pathlib import Path

import requests

NFLVERSE_URL = "https://github.com/nflverse/nflverse-data/releases/download/rosters/roster_{season}.csv"

# nflverse team code -> app team code. nflverse mostly matches us; these are the
# historical aliases that differ.
TEAM_ALIASES = {
    "LA": "LAR",   # LA Rams
    "OAK": "LV",   # pre-2020 Raiders
    "SD": "LAC",   # pre-2017 Chargers
    "STL": "LAR",  # pre-2016 Rams
    "WAS": "WSH",  # nflverse uses WAS, ESPN uses WSH
    "ARZ": "ARI",
    "BLT": "BAL",
    "CLV": "CLE",
    "HST": "HOU",
}

def normalise_team(code: str) -> str:
    code = (code or "").upper().strip()
    return TEAM_ALIASES.get(code, code)


def fetch_csv(season: int) -> str | None:
    url = NFLVERSE_URL.format(season=season)
    try:
        r = requests.get(url, timeout=30, allow_redirects=True)
        r.raise_for_status()
        # Require a real header AND a meaningful number of data rows, so we never
        # accept an empty / placeholder file for a season nflverse hasn't
        # actually published yet (this was the bug that produced bogus
        # "season 2026" rosters with non-existent players).
        if r.text and "full_name" in r.text[:2000] and r.text.count("\n") > 500:
            return r.text
        print(f"[roster] season {season}: file present but looks empty/placeholder; skipping.")
        return None
    except Exception as e:
        print(f"[roster] season {season} fetch failed: {e}")
        return None


def _inches_to_ft(height_raw: str) -> str:
    """nflverse stores height as total inches (character), e.g. '74' -> '6-2'.
    Some rows may already be in 'ft-in' form; pass those through."""
    h = (height_raw or "").strip()
    if not h:
        return ""
    if "-" in h:  # already ft-in
        return h
    try:
        inches = int(float(h))
        if inches <= 0:
            return ""
        return f"{inches // 12}-{inches % 12}"
    except (TypeError, ValueError):
        return h


def _round_from_pick(pick: int) -> int:
    """Approximate draft round from overall pick number (modern 32-team draft:
    32 picks/round, plus compensatory picks push later rounds slightly).
    Returns 0 when pick is unknown/undrafted."""
    if not pick or pick <= 0:
        return 0
    # Rounds 1-7 boundaries are roughly multiples of 32, but comp picks extend
    # rounds 3-7. Use cumulative thresholds that match recent drafts well.
    thresholds = [32, 64, 105, 144, 180, 220, 262]
    for i, t in enumerate(thresholds, start=1):
        if pick <= t:
            return i
    return 7


def build(out_path: str, season: int | None = None) -> None:
    # Determine season: try requested (or current year), fall back one year.
    now = datetime.now(timezone.utc)
    candidates = []
    if season:
        candidates = [season]
    else:
        # Detect the latest season nflverse has ACTUALLY published. We probe
        # from the current year downward; fetch_csv rejects empty/placeholder
        # files, so the first one with real data wins. Going back a few years
        # guarantees we never end up with an empty roster.
        candidates = [now.year, now.year - 1, now.year - 2]

    text = None
    used_season = None
    for s in candidates:
        text = fetch_csv(s)
        if text:
            used_season = s
            break

    if not text:
        print("[roster] No nflverse roster available; writing nothing.")
        return

    # Statuses that mean the player has LEFT the team — always drop these.
    departed = {"CUT", "RET", "FA", "DEV-RET", "TRC", "UDF", "WAI", "EXP"}

    reader = csv.DictReader(io.StringIO(text))
    teams: dict[str, list[dict]] = {}
    for row in reader:
        status = (row.get("status") or "").strip()
        if status.upper() in departed:
            continue
        team = normalise_team(row.get("team", ""))
        if not team:
            continue

        first = (row.get("first_name") or "").strip()
        last = (row.get("last_name") or "").strip()
        if not first and not last:
            full = (row.get("full_name") or "").strip()
            parts = full.split(" ", 1)
            first = parts[0] if parts else ""
            last = parts[1] if len(parts) > 1 else ""

        def to_int(v, default=0):
            try:
                return int(float(v))
            except (TypeError, ValueError):
                return default

        jersey = to_int(row.get("jersey_number"), 0)
        weight = to_int(row.get("weight"), 0)
        years = to_int(row.get("years_exp"), 0)

        pos = (row.get("position") or row.get("depth_chart_position") or "").strip().upper()
        depth = (row.get("depth_chart_position") or "").strip()

        # Draft info (nflverse roster carries these directly).
        draft_year = to_int(row.get("entry_year"), 0)
        draft_pick = to_int(row.get("draft_number"), 0)
        draft_club = normalise_team(row.get("draft_club", "")) if row.get("draft_club") else ""
        # Round can be derived from the overall pick number (picks are sequential
        # within rounds; this matches nflverse's own draft_round for modern
        # 7-round, 32-team drafts closely enough for display).
        draft_round = _round_from_pick(draft_pick)

        player = {
            "first": first,
            "last": last,
            "pos": pos or "—",
            "jersey": jersey,
            "height": _inches_to_ft(row.get("height") or ""),
            "weight": weight,
            "college": (row.get("college") or "").strip(),
            "years": years,
            "status": status or "ACT",
            "espn_id": (row.get("espn_id") or "").strip(),
            "depth": depth,
            # Draft (0 / empty when undrafted or unknown).
            "draft_year": draft_year,
            "draft_round": draft_round,
            "draft_pick": draft_pick,
            "draft_club": draft_club,
        }
        teams.setdefault(team, []).append(player)

    # Sort each team's players by position group then jersey for a stable list.
    pos_order = ["QB","RB","FB","WR","TE","OL","T","G","C","OT","LT","LG","RG","RT",
                 "DL","DE","DT","NT","LB","OLB","ILB","MLB","DB","CB","S","FS","SS",
                 "K","P","LS"]
    def sort_key(p):
        try:
            pi = pos_order.index(p["pos"])
        except ValueError:
            pi = 99
        return (pi, p["jersey"] if p["jersey"] else 999)
    for t in teams:
        teams[t].sort(key=sort_key)

    payload = {
        "version": 1,
        "generated_at": now.isoformat(),
        "season": used_season,
        "source": "nflverse",
        "team_count": len(teams),
        "teams": teams,
    }
    out = Path(out_path)
    out.parent.mkdir(parents=True, exist_ok=True)
    with open(out, "w") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    total = sum(len(v) for v in teams.values())
    print(f"[roster] wrote {total} players across {len(teams)} teams (season {used_season}) -> {out}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="output/rosters-latest.json")
    p.add_argument("--season", type=int, default=None)
    args = p.parse_args()
    build(args.out, args.season)
