"""
Build a unified feed JSON file for the iOS app to consume.

Inputs (best-effort, all optional):
  - X collector (requires bearer token)
  - NFL.com scraper
  - RSS feeds (ESPN, CBS, FOX, NBC, PFT, PFF, Yahoo, Bleacher Report)

Sources are deduplicated by normalised title, then scored by reliability and
cross-source confirmation. Output is sorted newest-first.

Usage:
  python -m api.build_feed --config config.yml --out output/intel-latest.json
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import yaml

from collectors import x_collector, nfl_official, rss_collector
from scorers.reliability_scorer import score_items


def build(config_path: str, out_path: str) -> None:
    with open(config_path, "r") as f:
        cfg = yaml.safe_load(f)

    items = []

    # X (Twitter) — needs bearer token
    try:
        items += x_collector.collect(cfg)
        print(f"[build] X collector: total now {len(items)}")
    except Exception as e:
        print(f"[build] X collector failed: {e}")

    # NFL.com scraping
    try:
        items += nfl_official.collect(cfg)
        print(f"[build] NFL.com collector: total now {len(items)}")
    except Exception as e:
        print(f"[build] NFL.com collector failed: {e}")

    # RSS — multiple major outlets, all free
    try:
        items += rss_collector.collect_all()
        print(f"[build] RSS collector: total now {len(items)}")
    except Exception as e:
        print(f"[build] RSS collector failed: {e}")

    # Score (dedup + multi-source bonus)
    items = score_items(items, cfg)

    # Sort newest first
    items.sort(key=lambda i: i.published_at, reverse=True)

    payload = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "count": len(items),
        "items": [i.model_dump() for i in items],
    }

    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(payload, f, ensure_ascii=False, indent=2)
    print(f"Wrote {len(items)} items → {out_path}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--config", default="config.yml")
    p.add_argument("--out", default="output/intel-latest.json")
    args = p.parse_args()
    build(args.config, args.out)
