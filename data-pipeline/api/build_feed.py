"""
Build a unified feed JSON file for the iOS app to consume.

Usage:
  python -m api.build_feed --config config.yml --out output/intel-latest.json

This is invoked by GitHub Actions on a schedule (see .github/workflows/collect-news.yml).
"""

from __future__ import annotations

import argparse
import json
from datetime import datetime, timezone
from pathlib import Path

import yaml

from collectors import x_collector, nfl_official
from scorers.reliability_scorer import score_items


def build(config_path: str, out_path: str) -> None:
    with open(config_path, "r") as f:
        cfg = yaml.safe_load(f)

    items = []
    items += x_collector.collect(cfg)
    items += nfl_official.collect(cfg)

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
