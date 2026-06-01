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
# Player-level dataset carries authoritative draft_year / draft_round /
# draft_pick / draft_team, which the roster file often leaves blank.
NFLVERSE_PLAYERS_URL = "https://github.com/nflverse/nflverse-data/releases/download/players/players.csv"

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


def load_players_draft_index() -> dict[str, dict]:
    """
    Download nflverse players.csv and build a draft lookup keyed by BOTH
    gsis_id and espn_id, so we can enrich roster rows that lack draft data.

    Each value: {"year": int, "round": int, "pick": int, "team": str}.
    Returns an empty dict if the file can't be loaded (we degrade gracefully).
    """
    try:
        r = requests.get(NFLVERSE_PLAYERS_URL, timeout=60, allow_redirects=True)
        r.raise_for_status()
        text = r.text
        if not text or "gsis_id" not in text[:2000]:
            print("[roster] players.csv missing expected columns; skipping draft enrich.")
            return {}
    except Exception as e:
        print(f"[roster] players.csv fetch failed: {e}; skipping draft enrich.")
        return {}

    def to_int(v, default=0):
        try:
            return int(float(v))
        except (TypeError, ValueError):
            return default

    def norm_espn(v: str) -> str:
        v = (v or "").strip()
        if not v:
            return ""
        # players.csv espn_id can be float-like ("12345.0"); normalise to int str.
        try:
            return str(int(float(v)))
        except (TypeError, ValueError):
            return v

    index: dict[str, dict] = {}
    reader = csv.DictReader(io.StringIO(text))
    # Log the actual header once, so we can see real column names in CI logs.
    if reader.fieldnames:
        print(f"[roster] players.csv columns: {reader.fieldnames}")
    for row in reader:
        year = to_int(row.get("draft_year"))
        rnd = to_int(row.get("draft_round"))
        pick = to_int(row.get("draft_pick"))
        team = normalise_team(row.get("draft_team", "")) if row.get("draft_team") else ""
        if not (year or rnd or pick or team):
            continue
        rec = {"year": year, "round": rnd, "pick": pick, "team": team}
        gsis = (row.get("gsis_id") or "").strip()
        espn = norm_espn(row.get("espn_id", ""))
        name = (row.get("display_name") or row.get("full_name") or "").strip().lower()
        if gsis:
            index[f"gsis:{gsis}"] = rec
        if espn:
            index[f"espn:{espn}"] = rec
        if name:
            # Name collisions are possible but rare; first writer wins which is
            # fine for a display-only fallback.
            index.setdefault(f"name:{name}", rec)
    print(f"[roster] loaded draft index for {len(index)} player keys from players.csv")
    return index


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

    # Authoritative draft data (round/pick/team) keyed by gsis_id and espn_id.
    draft_index = load_players_draft_index()
    draft_matched = 0

    def norm_espn(v: str) -> str:
        v = (v or "").strip()
        if not v:
            return ""
        try:
            return str(int(float(v)))
        except (TypeError, ValueError):
            return v

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

        # Draft info. Start from whatever the roster row carries...
        draft_year = to_int(row.get("entry_year"), 0)
        draft_pick = to_int(row.get("draft_number"), 0)
        draft_club = normalise_team(row.get("draft_club", "")) if row.get("draft_club") else ""
        draft_round = 0

        # ...then enrich from players.csv (authoritative round/pick/team), which
        # the roster file frequently leaves blank. Match by gsis_id, then
        # espn_id, then full name as a last resort.
        gsis = (row.get("gsis_id") or "").strip()
        espn = norm_espn(row.get("espn_id", ""))
        full_name = (row.get("full_name") or f"{first} {last}").strip().lower()
        rec = None
        if gsis and f"gsis:{gsis}" in draft_index:
            rec = draft_index[f"gsis:{gsis}"]
        elif espn and f"espn:{espn}" in draft_index:
            rec = draft_index[f"espn:{espn}"]
        elif full_name and f"name:{full_name}" in draft_index:
            rec = draft_index[f"name:{full_name}"]
        if rec:
            draft_matched += 1
            draft_year = rec["year"] or draft_year
            draft_round = rec["round"] or draft_round
            draft_pick = rec["pick"] or draft_pick
            draft_club = rec["team"] or draft_club

        # If round is still unknown but we have an overall pick, approximate it.
        if not draft_round and draft_pick:
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
    print(f"[roster] draft info matched for {draft_matched}/{total} players")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="output/rosters-latest.json")
    p.add_argument("--season", type=int, default=None)
    args = p.parse_args()
    build(args.out, args.season)
