"""
Daily Digest generator powered by Claude.

This version produces a richer, magazine-style daily report rather than a
bullet list. It also implements aggressive cost controls:

  1. Claude Haiku 4.5 by default (about 1/12 the cost of Sonnet)
     Override with --model claude-sonnet-4-5 when you want premium output.
  2. Cache check: if the previous digest was generated < SKIP_HOURS hours ago
     AND the source feed has not meaningfully changed, skip the API call.
  3. Hard token caps on both input and output.
  4. Best-N item pre-filter so the model never sees more than 25 items.

Output schema (digest-latest.json):

{
  "version": 2,
  "generated_at": ISO timestamp,
  "time_of_day": "morning" | "evening",
  "model": "claude-haiku-4-5-20251001" | ...,
  "skipped": false,
  "digest": {
    "headline_en": "...", "headline_ja": "...",
    "lead_en": "...",     "lead_ja": "...",
    "body_en": "<long-form article, 4-6 paragraphs>",
    "body_ja": "<同上、日本語>",
    "topics": [{ ... }],
    "watch_tomorrow_en": "...", "watch_tomorrow_ja": "..."
  }
}
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
from datetime import datetime, timezone, timedelta
from pathlib import Path

import requests


CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
DEFAULT_MODEL = "claude-haiku-4-5-20251001"
MAX_INPUT_ITEMS = 25
MAX_OUTPUT_TOKENS = 3000
SKIP_HOURS = 6  # don't regenerate if last digest is fresher than this


def load_feed(feed_path: Path) -> list[dict]:
    if not feed_path.exists():
        return []
    with open(feed_path) as f:
        data = json.load(f)
    return data.get("items", []) if isinstance(data, dict) else data


def rank_items(items: list[dict]) -> list[dict]:
    """Top-N items by reliability + cross-source bonus + breakout signals."""
    def score(it: dict) -> float:
        rel = float(it.get("reliability", 0.5))
        srcs = it.get("sources", [])
        cross_source_bonus = min(0.2, 0.05 * len(set(srcs)))
        kind_bonus = {"trade": 0.18, "signing": 0.12, "injury": 0.08, "presser": 0.04}.get(it.get("kind", ""), 0)
        return rel + cross_source_bonus + kind_bonus
    return sorted(items, key=score, reverse=True)[:MAX_INPUT_ITEMS]


def feed_fingerprint(items: list[dict]) -> str:
    """Stable hash of the ranked feed so we can detect 'nothing new'."""
    h = hashlib.sha1()
    for it in items[:MAX_INPUT_ITEMS]:
        title = (it.get("title") or "")[:200]
        h.update(title.encode("utf-8"))
        h.update(b"|")
    return h.hexdigest()


def should_skip(out_path: Path, current_fp: str) -> bool:
    """Skip regeneration if recent and the feed hasn't changed."""
    if not out_path.exists():
        return False
    try:
        with open(out_path) as f:
            prev = json.load(f)
    except Exception:
        return False
    # Never skip if the previous digest was a fallback / error placeholder.
    # Otherwise a one-time "API key missing" result would stick for SKIP_HOURS
    # even after the key is fixed. A real digest always has body text.
    prev_digest = prev.get("digest", {})
    prev_body = (prev_digest.get("body_en") or "") + (prev_digest.get("body_ja") or "")
    prev_headline = prev_digest.get("headline_en", "")
    looks_like_fallback = (
        not prev_body.strip()
        or prev_headline == "Digest temporarily unavailable"
    )
    if looks_like_fallback:
        return False

    prev_fp = prev.get("source_fingerprint")
    prev_at = prev.get("generated_at")
    if not prev_fp or not prev_at:
        return False
    if prev_fp != current_fp:
        return False
    try:
        prev_dt = datetime.fromisoformat(prev_at.replace("Z", "+00:00"))
    except Exception:
        return False
    age = datetime.now(timezone.utc) - prev_dt
    return age < timedelta(hours=SKIP_HOURS)


def build_prompt(items: list[dict], time_of_day: str) -> str:
    bullets = []
    for i, it in enumerate(items[:20], 1):
        sources = ", ".join(it.get("sources", []))
        bullets.append(
            f"{i}. [{it.get('kind', 'news').upper()}] {it.get('title', '')}\n"
            f"   team: {it.get('team_abbrev', '—')}, sources: {sources}, reliability: {it.get('reliability', 0):.2f}\n"
            f"   excerpt: {it.get('excerpt', '')[:300]}"
        )
    items_block = "\n".join(bullets)

    tone_note = (
        "It's morning — frame the day ahead. What should fans watch for today?"
        if time_of_day == "morning"
        else "It's evening — recap the day. What were the biggest storylines?"
    )

    return f"""You are the lead NFL analyst for "Redzone Tracker", a serious fan study app.
Write the {time_of_day.upper()} daily report. Your readers are NFL diehards — they want
analysis, context, and synthesis, NOT just bullet points.

{tone_note}

Today's most reliable items (already ranked by source credibility):

{items_block}

Write a magazine-style daily report in BOTH English AND Japanese. Output VALID JSON ONLY
matching this schema:

{{
  "headline_en": "<one striking headline, max 90 chars>",
  "headline_ja": "<同じ趣旨の日本語見出し、最大70文字>",
  "lead_en": "<2-3 sentence lead paragraph that hooks the reader, ~300 chars>",
  "lead_ja": "<日本語リード、約200文字>",
  "body_en": "<4-6 paragraphs of substantive analysis. Connect related items.
    Cite team abbreviations (KC, BUF, etc). Bring in context where useful
    (cap situation, division standing, recent trends). Avoid lists — write
    flowing prose. Use double newlines (\\n\\n) between paragraphs.>",
  "body_ja": "<同じ内容を日本語で。4-6パラグラフ、\\n\\nで区切る。NFLファン用語使用OK>",
  "topics": [
    {{
      "title_en": "<topic title>",
      "title_ja": "<日本語タイトル>",
      "body_en": "<2-4 sentences with concrete analysis>",
      "body_ja": "<日本語で同内容>",
      "team_abbrev": "<KC / BUF / nil>",
      "importance": "high|medium|low"
    }}
    // 4-6 topics ordered by importance
  ],
  "watch_tomorrow_en": "<one sharp sentence on what to watch next>",
  "watch_tomorrow_ja": "<日本語で同じ>"
}}

Rules:
- Be analytical, not promotional. Don't sugarcoat.
- Connect dots across stories when relevant (e.g., 'with X out, Y's role grows').
- For Japanese: use natural NFLファン用語. Don't directly translate idioms.
- Output JSON ONLY. No markdown fences."""


def call_claude(prompt: str, api_key: str, model: str) -> dict:
    response = requests.post(
        CLAUDE_API_URL,
        headers={
            "x-api-key": api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        },
        json={
            "model": model,
            "max_tokens": MAX_OUTPUT_TOKENS,
            "messages": [{"role": "user", "content": prompt}],
        },
        timeout=90,
    )
    if response.status_code >= 400:
        # Include the API's own error body — it states the real cause
        # (e.g. "credit balance is too low", "invalid x-api-key", model not found).
        raise RuntimeError(f"HTTP {response.status_code}: {response.text[:400]}")
    body = response.json()
    text = body["content"][0]["text"].strip()
    if text.startswith("```"):
        text = text.split("```", 2)[1]
        if text.startswith("json"):
            text = text[4:]
        text = text.strip()
    return json.loads(text)


def build(feed_path: Path, out_path: Path, time_of_day: str, model: str, force: bool = False) -> None:
    items = load_feed(feed_path)
    if not items:
        print("[digest] No items to summarize, skipping.")
        return
    ranked = rank_items(items)
    fingerprint = feed_fingerprint(ranked)

    if not force and should_skip(out_path, fingerprint):
        print(f"[digest] Same feed within {SKIP_HOURS}h, skipping Claude call (no cost incurred).")
        return

    api_key = os.environ.get("ANTHROPIC_API_KEY")
    if not api_key:
        print("[digest] ANTHROPIC_API_KEY not set. Writing fallback empty digest.")
        digest_payload = {
            "headline_en": "Digest temporarily unavailable",
            "headline_ja": "ダイジェスト一時利用不可",
            "lead_en": "API key missing on the server. Check GitHub Secrets.",
            "lead_ja": "サーバー側のAPIキーが未設定です。GitHub Secrets を確認してください。",
            "body_en": "",
            "body_ja": "",
            "topics": [],
            "watch_tomorrow_en": "",
            "watch_tomorrow_ja": "",
        }
        skipped = False
    else:
        prompt = build_prompt(ranked, time_of_day)
        try:
            digest_payload = call_claude(prompt, api_key, model)
            skipped = False
        except Exception as e:
            # Don't silently exit — surface the real reason in the published file
            # so the app (and we) can see exactly why it failed (auth, billing,
            # rate limit, bad model name, etc.) instead of a generic message.
            detail = str(e)
            print(f"[digest] Claude call failed: {detail}")
            digest_payload = {
                "headline_en": "Digest generation failed",
                "headline_ja": "ダイジェスト生成に失敗しました",
                "lead_en": f"Claude API call failed: {detail[:300]}",
                "lead_ja": f"Claude API 呼び出しに失敗しました: {detail[:300]}",
                "body_en": "",
                "body_ja": "",
                "topics": [],
                "watch_tomorrow_en": "",
                "watch_tomorrow_ja": "",
            }
            skipped = False

    output = {
        "version": 2,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "time_of_day": time_of_day,
        "model": model,
        "skipped": skipped,
        "source_item_count": len(items),
        "ranked_item_count": len(ranked),
        "source_fingerprint": fingerprint,
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
    p.add_argument("--model", default=DEFAULT_MODEL,
                   help="claude-haiku-4-5-20251001 (cheap) or claude-sonnet-4-5 (premium)")
    p.add_argument("--force", action="store_true", help="Skip the 'no-change' cache check")
    args = p.parse_args()
    build(Path(args.feed), Path(args.out), args.time_of_day, args.model, args.force)
