"""
X (Twitter) collector for NFL insider accounts.

Pulls recent tweets from curated insider / team / beat-writer lists,
classifies them by topic (trade / signing / injury / presser / rumor),
and writes them to the unified Intel JSON output.

Notes:
- Requires a bearer token configured in config.yml under `x.bearer_token`.
- The X API v2 free tier is restrictive; this collector is designed
  to be polite and respect rate limits.
"""

from __future__ import annotations

import os
import re
import yaml
import json
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable

try:
    import tweepy  # type: ignore
except ImportError:
    tweepy = None  # gracefully degrade for local development without keys

from collectors.common import NewsItem, classify_kind, normalise_text


def load_config(path: str = "config.yml") -> dict:
    with open(path, "r") as f:
        return yaml.safe_load(f)


def collect(config: dict) -> list[NewsItem]:
    """Return a list of NewsItem objects from monitored X accounts."""

    if tweepy is None:
        print("[x_collector] tweepy not installed; skipping.")
        return []

    token = config.get("x", {}).get("bearer_token")
    if not token or token == "REPLACE_ME":
        print("[x_collector] No bearer token; skipping.")
        return []

    client = tweepy.Client(bearer_token=token, wait_on_rate_limit=True)

    accounts = list(_iter_accounts(config))
    items: list[NewsItem] = []

    for handle in accounts:
        try:
            user = client.get_user(username=handle)
            if user.data is None:
                continue
            tweets = client.get_users_tweets(
                id=user.data.id,
                max_results=10,
                tweet_fields=["created_at", "entities", "public_metrics"],
                exclude=["replies", "retweets"],
            )
            if tweets.data:
                for t in tweets.data:
                    item = _to_news_item(handle, t)
                    if item:
                        items.append(item)
        except Exception as e:
            print(f"[x_collector] error for @{handle}: {e}")

    return items


def _iter_accounts(config: dict) -> Iterable[str]:
    watch = config.get("x", {}).get("watch_accounts", {})
    for group in ("insiders", "teams", "beat_writers"):
        for handle in watch.get(group, []) or []:
            yield handle


def _to_news_item(handle: str, tweet) -> NewsItem | None:
    text = normalise_text(tweet.text)
    if not text or len(text) < 20:
        return None
    kind = classify_kind(text)
    return NewsItem(
        kind=kind,
        title=text.split("\n")[0][:160],
        excerpt=text,
        sources=[f"@{handle}"],
        team_abbrev=_infer_team(text),
        url=f"https://x.com/{handle}/status/{tweet.id}",
        published_at=tweet.created_at.astimezone(timezone.utc).isoformat(),
    )


_TEAM_HINTS = {
    "KC": ["chiefs", "kansas city"],
    "BUF": ["bills", "buffalo"],
    "SF": ["49ers", "niners"],
    "DAL": ["cowboys"],
    "PHI": ["eagles"],
    "BAL": ["ravens"],
    # extend
}


def _infer_team(text: str) -> str | None:
    lower = text.lower()
    for abbrev, hints in _TEAM_HINTS.items():
        for h in hints:
            if h in lower:
                return abbrev
    return None


if __name__ == "__main__":
    cfg = load_config()
    items = collect(cfg)
    print(f"Collected {len(items)} items from X.")
    out = Path(cfg.get("output", {}).get("dir", "./output"))
    out.mkdir(parents=True, exist_ok=True)
    date = datetime.now(timezone.utc).strftime("%Y%m%d")
    fname = out / cfg.get("output", {}).get("filename", "intel-{date}.json").format(date=date)
    with open(fname, "w") as f:
        json.dump([item.model_dump() for item in items], f, ensure_ascii=False, indent=2)
    print(f"Wrote {fname}")
