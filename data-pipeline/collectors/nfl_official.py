"""
NFL.com official news collector.
Scrapes the official news index for headlines + summaries.
"""

from __future__ import annotations

import requests
from bs4 import BeautifulSoup
from datetime import datetime, timezone

from collectors.common import NewsItem, classify_kind, normalise_text


def collect(config: dict) -> list[NewsItem]:
    base = config.get("nfl_official", {}).get("base", "https://www.nfl.com")
    url = base + config.get("nfl_official", {}).get("endpoints", {}).get("news", "/news")

    try:
        r = requests.get(url, timeout=15, headers={"User-Agent": "f/Room collector (research)"})
        r.raise_for_status()
    except Exception as e:
        print(f"[nfl_official] fetch failed: {e}")
        return []

    soup = BeautifulSoup(r.text, "lxml")
    items: list[NewsItem] = []

    # NFL.com markup changes often; this is a best-effort selector.
    for article in soup.select("article")[:25]:
        title_el = article.find(["h2", "h3"])
        if not title_el:
            continue
        title = normalise_text(title_el.get_text())
        if not title:
            continue
        excerpt_el = article.find("p")
        excerpt = normalise_text(excerpt_el.get_text()) if excerpt_el else title

        link = article.find("a", href=True)
        href = (base + link["href"]) if link and link["href"].startswith("/") else (link["href"] if link else None)

        items.append(NewsItem(
            kind=classify_kind(title + " " + excerpt),
            title=title,
            excerpt=excerpt[:280],
            sources=["NFL.com"],
            reliability=0.95,
            url=href,
            published_at=datetime.now(timezone.utc).isoformat(),
        ))

    return items


if __name__ == "__main__":
    import yaml, json
    from pathlib import Path
    cfg = yaml.safe_load(open("config.yml"))
    items = collect(cfg)
    print(f"Collected {len(items)} items from NFL.com")
    out = Path(cfg.get("output", {}).get("dir", "./output"))
    out.mkdir(parents=True, exist_ok=True)
    with open(out / "nfl_official_latest.json", "w") as f:
        json.dump([i.model_dump() for i in items], f, ensure_ascii=False, indent=2)
