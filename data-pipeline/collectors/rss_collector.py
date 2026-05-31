"""
RSS feed collector for major NFL outlets.

Pulls from ESPN, CBS Sports, FOX Sports, NBC Sports, etc.
All sources are free (no API key, no rate limits) since we just read the RSS.

Run via GitHub Actions every 30 minutes alongside the X collector.
"""

from __future__ import annotations

import argparse
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional
from xml.etree import ElementTree as ET

import requests

from collectors.common import NewsItem, classify_kind, normalise_text


# Each source: (label, url, baseline_reliability)
SOURCES = [
    ("ESPN NFL",         "https://www.espn.com/espn/rss/nfl/news", 0.92),
    ("CBS Sports NFL",   "https://www.cbssports.com/rss/headlines/nfl/", 0.88),
    ("FOX Sports NFL",   "https://api.foxsports.com/v1/rss?partnerKey=zBaFxRyGKCfxBagJG9b8pqLyndmvo7UU&tags=nfl", 0.85),
    ("NBC Sports NFL",   "https://www.nbcsports.com/nfl/feed", 0.86),
    ("Pro Football Talk","https://profootballtalk.nbcsports.com/feed/", 0.85),
    ("Yahoo Sports NFL", "https://sports.yahoo.com/nfl/rss.xml", 0.78),
    ("Bleacher Report",  "https://bleacherreport.com/articles/feed?tag=nfl", 0.74),
    ("PFF NFL",          "https://www.pff.com/news/feed", 0.88),
    ("NFL.com Top News", "https://www.nfl.com/news/rss.xml", 0.95),
]

HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Macintosh; Intel Mac OS X) AppleWebKit/605.1.15 "
        "(Redzone Tracker RSS collector)"
    ),
    "Accept": "application/rss+xml, application/xml, text/xml",
}


# XML namespace handling
NAMESPACES = {
    "atom": "http://www.w3.org/2005/Atom",
    "media": "http://search.yahoo.com/mrss/",
    "content": "http://purl.org/rss/1.0/modules/content/",
    "dc": "http://purl.org/dc/elements/1.1/",
}


def _parse_rss(xml_text: str) -> list[dict]:
    """Best-effort RSS / Atom parser. Returns list of dicts with title/description/link/pubDate."""
    items: list[dict] = []
    try:
        root = ET.fromstring(xml_text)
    except ET.ParseError:
        return items

    # Try RSS 2.0 first: channel/item
    for item in root.iter():
        tag = item.tag.lower()
        if tag.endswith("item") or tag.endswith("entry"):
            title = _find_text(item, "title")
            desc = _find_text(item, "description") or _find_text(item, "summary") or _find_text(item, "content")
            link = _find_link(item)
            pub = _find_text(item, "pubdate") or _find_text(item, "published") or _find_text(item, "updated")
            if title:
                items.append({
                    "title": normalise_text(title),
                    "description": normalise_text(_strip_html(desc or "")),
                    "link": link,
                    "pubDate": pub,
                })
    return items


def _find_text(elem, tag_local: str) -> Optional[str]:
    target = tag_local.lower()
    for child in elem.iter():
        local = child.tag.split("}")[-1].lower()
        if local == target and child.text:
            return child.text
    return None


def _find_link(elem) -> Optional[str]:
    for child in elem.iter():
        local = child.tag.split("}")[-1].lower()
        if local == "link":
            # RSS: text content; Atom: href attribute
            if child.text and child.text.strip():
                return child.text.strip()
            href = child.attrib.get("href")
            if href:
                return href
    return None


_HTML_RE = re.compile(r"<[^>]+>")


def _strip_html(text: str) -> str:
    return _HTML_RE.sub("", text)


def collect_one(source_label: str, url: str, reliability: float) -> list[NewsItem]:
    try:
        r = requests.get(url, headers=HEADERS, timeout=15)
        r.raise_for_status()
    except Exception as e:
        print(f"[rss] {source_label} failed: {e}")
        return []

    entries = _parse_rss(r.text)
    items: list[NewsItem] = []
    for entry in entries[:30]:  # cap per-source
        title = entry["title"]
        desc = entry["description"] or title
        if not title:
            continue
        items.append(NewsItem(
            kind=classify_kind(title + " " + desc),
            title=title,
            excerpt=desc[:300],
            sources=[source_label],
            reliability=reliability,
            team_abbrev=_infer_team(title + " " + desc),
            url=entry["link"],
            published_at=entry["pubDate"] or datetime.now(timezone.utc).isoformat(),
        ))
    return items


_TEAM_HINTS = {
    "ARI": ["cardinals"], "ATL": ["falcons"], "BAL": ["ravens"], "BUF": ["bills"],
    "CAR": ["panthers"], "CHI": ["bears"], "CIN": ["bengals"], "CLE": ["browns"],
    "DAL": ["cowboys"], "DEN": ["broncos"], "DET": ["lions"], "GB":  ["packers"],
    "HOU": ["texans"], "IND": ["colts"], "JAX": ["jaguars"], "KC":  ["chiefs"],
    "LV":  ["raiders"], "LAC": ["chargers"], "LAR": ["rams"], "MIA": ["dolphins"],
    "MIN": ["vikings"], "NE":  ["patriots"], "NO":  ["saints"], "NYG": ["giants"],
    "NYJ": ["jets"], "PHI": ["eagles"], "PIT": ["steelers"], "SF":  ["49ers", "niners"],
    "SEA": ["seahawks"], "TB":  ["buccaneers", "bucs"], "TEN": ["titans"], "WAS": ["commanders"],
}


def _infer_team(text: str) -> Optional[str]:
    lower = text.lower()
    for abbrev, hints in _TEAM_HINTS.items():
        for h in hints:
            if h in lower:
                return abbrev
    return None


def collect_all() -> list[NewsItem]:
    out: list[NewsItem] = []
    for label, url, rel in SOURCES:
        items = collect_one(label, url, rel)
        print(f"[rss] {label}: {len(items)} items")
        out.extend(items)
        time.sleep(0.3)
    return out


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--out", default="output/rss-latest.json")
    args = p.parse_args()
    items = collect_all()
    print(f"[rss] total: {len(items)} items")
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    payload = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "count": len(items),
        "items": [it.model_dump() for it in items],
    }
    with open(out, "w") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"[rss] wrote {out}")
