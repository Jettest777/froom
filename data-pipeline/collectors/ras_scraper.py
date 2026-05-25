"""
RAS (Relative Athletic Score) scraper.

Pulls athletic scores + raw combine numbers from Kent Lee Platte's site:
https://ras.football/

Per-player URL format (varies):
  https://ras.football/ras-card/?first=Patrick&last=Mahomes
  Or season-aggregate listings at https://ras.football/all-ras-scores-{year}/

We try the lookup endpoint first, fall back to a name-based search.

This collector is best-effort and very polite (1 req/sec). Respect the site.
"""

from __future__ import annotations

import argparse
import json
import re
import time
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from urllib.parse import quote

import requests
from bs4 import BeautifulSoup


HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 "
        "(Redzone Tracker personal study tool)"
    ),
    "Accept-Language": "en-US,en;q=0.9",
}
POLITE_DELAY_SECONDS = 1.2


@dataclass
class RASEntry:
    playerName: str
    position: str
    height: Optional[float]              # inches
    weight: Optional[float]              # pounds
    fortyYard: Optional[float]           # seconds
    verticalJump: Optional[float]        # inches
    broadJump: Optional[float]           # inches
    benchPress: Optional[int]            # reps @ 225
    threeConeShuttle: Optional[float]
    shortShuttle: Optional[float]
    rasOverall: Optional[float]          # 0..10
    rasSize: Optional[float]
    rasSpeed: Optional[float]
    rasExplosion: Optional[float]
    rasAgility: Optional[float]
    rasStrength: Optional[float]
    college: Optional[str]
    draftYear: Optional[int]
    sourceURL: str


def _to_float(text: Optional[str]) -> Optional[float]:
    if not text:
        return None
    m = re.search(r"-?\d+\.?\d*", text)
    return float(m.group()) if m else None


def _to_int(text: Optional[str]) -> Optional[int]:
    f = _to_float(text)
    return int(f) if f is not None else None


def _height_to_inches(text: Optional[str]) -> Optional[float]:
    """Convert '6'3"' or '75.0' to inches."""
    if not text:
        return None
    m = re.match(r"(\d+)'(\d+)", text)
    if m:
        return int(m.group(1)) * 12 + int(m.group(2))
    return _to_float(text)


def fetch_player_ras(first: str, last: str) -> Optional[RASEntry]:
    """Try the RAS card lookup. Markup may shift; this is best-effort."""
    url = f"https://ras.football/ras-card/?first={quote(first)}&last={quote(last)}"
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
    except Exception as e:
        print(f"[ras] fetch failed for {first} {last}: {e}")
        return None

    soup = BeautifulSoup(r.text, "lxml")

    # Best-effort extraction — RAS cards typically have a definition list
    # with labels like "Forty", "Vertical", "Broad", "Bench" etc.

    fields: dict[str, str] = {}
    for label_el in soup.find_all(["dt", "th", "span", "strong"]):
        label = label_el.get_text(strip=True).lower()
        if not label:
            continue
        value_el = label_el.find_next(["dd", "td", "span"])
        if value_el is None:
            continue
        value = value_el.get_text(strip=True)
        fields[label] = value

    def find(*keywords) -> Optional[str]:
        for key in fields:
            for kw in keywords:
                if kw in key:
                    return fields[key]
        return None

    pos = find("position") or "—"
    height = _height_to_inches(find("height"))
    weight = _to_float(find("weight"))
    forty = _to_float(find("forty", "40 yard", "40-yard"))
    vertical = _to_float(find("vertical"))
    broad = _to_float(find("broad"))
    bench = _to_int(find("bench"))
    threecone = _to_float(find("three cone", "3-cone"))
    shuttle = _to_float(find("short shuttle", "20 yard shuttle"))
    ras = _to_float(find("ras", "overall ras"))
    size = _to_float(find("size"))
    speed = _to_float(find("speed"))
    explosion = _to_float(find("explosion"))
    agility = _to_float(find("agility"))
    strength = _to_float(find("strength"))
    college = find("college", "school")
    draft_year = _to_int(find("draft year", "year"))

    has_any = any(v is not None for v in [height, weight, forty, vertical, broad, bench, ras])
    if not has_any:
        return None

    return RASEntry(
        playerName=f"{first} {last}",
        position=pos,
        height=height,
        weight=weight,
        fortyYard=forty,
        verticalJump=vertical,
        broadJump=broad,
        benchPress=bench,
        threeConeShuttle=threecone,
        shortShuttle=shuttle,
        rasOverall=ras,
        rasSize=size,
        rasSpeed=speed,
        rasExplosion=explosion,
        rasAgility=agility,
        rasStrength=strength,
        college=college,
        draftYear=draft_year,
        sourceURL=url,
    )


def run_for_players(players: list[tuple[str, str]], out_dir: Path) -> None:
    out_dir.mkdir(parents=True, exist_ok=True)
    results = {}
    for first, last in players:
        print(f"[ras] fetching {first} {last}...")
        entry = fetch_player_ras(first, last)
        if entry:
            results[f"{first} {last}"] = asdict(entry)
        time.sleep(POLITE_DELAY_SECONDS)

    output = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "count": len(results),
        "players": results,
    }
    out_path = out_dir / "ras-latest.json"
    with open(out_path, "w") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"[ras] wrote {out_path}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="output")
    p.add_argument("--seed", default="ras-seed.json",
                   help="Path to a JSON file with a 'players' array of {first,last}")
    args = p.parse_args()

    if Path(args.seed).exists():
        with open(args.seed) as f:
            seed = json.load(f)
        players = [(p["first"], p["last"]) for p in seed.get("players", [])]
    else:
        # Default seed: a few well-known players
        players = [
            ("Patrick", "Mahomes"),
            ("Josh", "Allen"),
            ("Christian", "McCaffrey"),
            ("Travis", "Kelce"),
        ]

    run_for_players(players, Path(args.out))
