"""
Daily Digest generator powered by Claude.

Reads the most recent intel-latest.json (collected from X / NFL.com / ESPN),
ranks items by reliability + engagement signals, then asks Claude to write a
bilingual (EN + JA) digest summarizing the day's NFL storylines.

Output: data-pipeline/output/digest-latest.json
"""

from __future__ import annotations

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

import requests


CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
CLAUDE_MODEL = "claude-sonnet-4-5"
MAX_INPUT_ITEMS = 30
MAX_OUTPUT_TOKENS = 2000


def load_feed(feed_path: Path) -> list[dict]:
    if not feed_path.exists():
        return []
    with open(feed_path) as f:
        data = json.load(f)
    items = data.get("items", []) if isinstance(data, dict) else data
    return items


def rank_items(items: list[dict]) -> list[dict]:
    """Top-N items by reliability * (1 + recency_boost). Newest preferred."""
    def score(it: dict) -> float:
        reliability = float(it.get("reliability", 0.5))
        sources = it.get("sources", [])
        source_boost = min(0.2, 0.05 * len(set(sources)))
        kind = it.get("kind", "other")
        kind_boost = {"trade": 0.15, "signing": 0.10, "injury": 0.08, "presser": 0.05}.get(kind, 0)
        return reliability + source_boost + kind_boost
    sorted_items = sorted(items, key=score, reverse=True)
    return sorted_items[:MAX_INPUT_ITEMS]


def build_prompt(items: list[dict], time_of_day: str) -> str:
    bullets = []
    for i, it in enumerate(items[:20], 1):
        sources = ", ".join(it.get("sources", []))
        bullets.append(
            f"{i}. [{it.get('kind', 'news').upper()}] {it.get('title', '')} "
            f"(team: {it.get('team_abbrev', '—')}, sources: {sources}, "
            f"reliability: {it.get('reliability', 0):.2f})\n"
            f"   {it.get('excerpt', '')[:240]}"
        )
    items_block = "\n".join(bullets)

    return f"""You are an NFL analyst writing the {time_of_day} digest for a fan study app called
"Redzone Tracker". Your readers are passionate NFL fans who want to be caught up on the day's
most important storylines in 60 seconds of reading.

Here are today's most reliable news items (ranked by source credibility and impact):

{items_block}

Write a daily digest with the following JSON structure (output JSON ONLY, no prose around it):

{{
  "headline_en": "<one punchy headline summarizing the biggest story, max 80 chars>",
  "headline_ja": "<同じ趣旨の日本語見出し（70文字以内）>",
  "lead_en": "<2-3 sentence lead paragraph in English, max 280 chars>",
  "lead_ja": "<同じ内容を日本語で、180文字以内>",
  "topics": [
    {{
      "title_en": "<topic 1 title>",
      "title_ja": "<日本語タイトル>",
      "body_en": "<2-3 sentences explaining impact>",
      "body_ja": "<日本語で同じ内容>",
      "team_abbrev": "<KC / BUF / etc, optional>",
      "importance": "high|medium|low"
    }}
    // 3-5 topics, ordered by importance
  ],
  "watch_tomorrow_en": "<one sentence on what to watch next>",
  "watch_tomorrow_ja": "<日本語で同じ>"
}}

Constraints:
- Be punchy, not flowery. NFL fans want signal, not filler.
- Cite team abbreviations (KC, BUF, etc) when relevant.
- For Japanese: use natural NFLファン用語 (e.g., "オフェンスコーディネーター", "ドラフト1巡目").
- Output valid JSON only. No markdown fences."""


def call_claude(prompt: str, api_key: str) -> dict:
    response = requests.post(
        CLAUDE_API_URL,
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        json={
            "model": CLAUDE_MODEL,
            "max_tokens": MAX_OUTPUT_TOKENS,
            "messages": [
                {"role": "user", "content": prompt}
            ],
        },
        timeout=60,
    )
    response.raise_for_status()
    body = response.json()
    text = body["content"][0]["text"].strip()
    # Strip optional code fences just in case
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.strip()
    return json.loads(text)


def build(feed_path: Path, out_path: Path, time_of_day: str) -> None:
    items = load_feed(feed_path)
    if not items:
        print("[digest] No items to summarize, skipping.")
        return
    ranked = rank_items(items)

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("[digest] ANTHROPIC_API_KEY not set. Writing a fallback empty digest.")
        digest_payload = {
            "headline_en": "No digest available",
            "headline_ja": "ダイジェスト未生成",
            "lead_en": "API key missing.",
            "lead_ja": "APIキー未設定です。",
            "topics": [],
            "watch_tomorrow_en": "",
            "watch_tomorrow_ja": "",
        }
    else:
        prompt = build_prompt(ranked, time_of_day)
        try:
            digest_payload = call_claude(prompt, api_key)
        except Exception as e:
            print(f"[digest] Claude call failed: {e}")
            return

    output = {
        "version": 1,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "time_of_day": time_of_day,
        "source_item_count": len(items),
        "ranked_item_count": len(ranked),
        "digest": digest_payload,
    }

    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w") as f:
        json.dump(output, f, ensure_ascii=False, indent=2)
    print(f"[digest] Wrote {out_path}")


if __name__ == "__main__":
    p = argparse.ArgumentParser()
    p.add_argument("--feed", default="output/intel-latest.json")
    p.add_argument("--out", default="output/digest-latest.json")
    p.add_argument("--time-of-day", default="morning", choices=["morning", "evening"])
    args = p.parse_args()
    build(Path(args.feed), Path(args.out), args.time_of_day)
