"""
Reliability scoring for collected news items.

Strategy:
- Each source has a baseline reliability weight (config.reliability.source_weight).
- When multiple sources confirm the same story, apply a multi_source_bonus.
- Output a 0..1 score that the iOS app surfaces as a percentage.
"""

from __future__ import annotations

from collections import defaultdict

from collectors.common import NewsItem


def score_items(items: list[NewsItem], config: dict) -> list[NewsItem]:
    cfg = config.get("reliability", {})
    weights: dict[str, float] = cfg.get("source_weight", {}) or {}
    bonus: float = cfg.get("multi_source_bonus", 0.04)

    # Group items by normalised title for cross-source bonus
    groups: dict[str, list[NewsItem]] = defaultdict(list)
    for item in items:
        key = _dedup_key(item.title)
        groups[key].append(item)

    scored: list[NewsItem] = []
    for key, group in groups.items():
        # base: max source weight in the group
        base = max(_source_weight(item, weights) for item in group)
        n_distinct_sources = len({s for item in group for s in item.sources})
        confirmed_bonus = bonus * max(0, n_distinct_sources - 1)
        score = min(1.0, base + confirmed_bonus)
        for item in group:
            item.reliability = round(score, 2)
            scored.append(item)
    return scored


def _source_weight(item: NewsItem, weights: dict[str, float]) -> float:
    if not item.sources:
        return weights.get("unknown", 0.5)
    # Try exact match (e.g. "@AdamSchefter" → "AdamSchefter")
    best = 0.0
    for src in item.sources:
        handle = src.lstrip("@").strip().lower()
        # match by handle
        for key, w in weights.items():
            if key.lower() == handle:
                best = max(best, w)
        # source-domain match
        lower = src.lower()
        if "nfl.com" in lower:
            best = max(best, weights.get("nfl_com", 0.9))
        elif "espn" in lower:
            best = max(best, weights.get("espn", 0.85))
        elif "official" in lower:
            best = max(best, weights.get("official_team", 0.95))
    return best if best > 0 else weights.get("unknown", 0.5)


def _dedup_key(title: str) -> str:
    # Crude dedup: lowercased + alpha-only fingerprint of the first 80 chars
    import re
    s = re.sub(r"[^a-z0-9]+", " ", title.lower()).strip()[:80]
    return s
