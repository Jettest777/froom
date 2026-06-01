"""
Shared Claude-powered Japanese translator for the data pipeline.

Used by both the news feed (title/excerpt) and anywhere else we need
high-quality, football-literate Japanese. The rules mirror the digest:

  - Keep proper nouns (player names, team/city names, coaches, stadiums) in
    their original English/Latin script — do NOT transliterate into katakana.
  - Translate for MEANING, not word-for-word. Use established Japanese
    American-football terminology where it exists; paraphrase idioms.
  - Read like a Japanese NFL writer wrote it, not a machine.

If no API key is present, or the call fails, callers should fall back to the
original English text (the app already handles a missing *_ja gracefully).
"""

from __future__ import annotations

import json
import os
from typing import Optional

import requests

CLAUDE_API_URL = "https://api.anthropic.com/v1/messages"
DEFAULT_MODEL = os.environ.get("TRANSLATE_MODEL", "claude-haiku-4-5-20251001")
MAX_TOKENS = int(os.environ.get("TRANSLATE_MAX_TOKENS", "4096"))

SYSTEM_RULES = (
    "You translate NFL news from English into natural Japanese for Japanese "
    "NFL fans. Rules:\n"
    "- KEEP all proper nouns in English/Latin script: player names "
    "(Patrick Mahomes, not パトリック・マホームズ), team and city names "
    "(Chiefs, Kansas City, KC), coaches, stadiums, league terms. Never "
    "transliterate names into katakana.\n"
    "- Translate for MEANING, not word-for-word. Use established Japanese "
    "American-football terms (サラリーキャップ, フリーエージェント, スナップ数, "
    "デプスチャート, レッドゾーン, etc.) and paraphrase idioms.\n"
    "- Output must read like a Japanese NFL writer wrote it — fluent, "
    "football-literate, never machine-like."
)


def _api_key() -> Optional[str]:
    return os.environ.get("ANTHROPIC_API_KEY")


def translate_batch(
    texts: list[str],
    model: str = DEFAULT_MODEL,
    timeout: int = 90,
) -> list[Optional[str]]:
    """
    Translate a list of English strings to Japanese in a single Claude call.

    Returns a list the same length as `texts`. Each element is the Japanese
    translation, or None if translation was unavailable for that item (caller
    should fall back to the English original).
    """
    if not texts:
        return []
    api_key = _api_key()
    if not api_key:
        print("[translate] ANTHROPIC_API_KEY not set; skipping translation.")
        return [None] * len(texts)

    # Number the inputs so we can map outputs back reliably.
    numbered = [{"id": i, "en": t} for i, t in enumerate(texts)]
    prompt = (
        SYSTEM_RULES
        + "\n\nTranslate each item's \"en\" into Japanese following the rules. "
        "Return ONLY valid JSON: an array of objects "
        '[{"id": <same id>, "ja": "<translation>"}], same length and order.\n\n'
        "Items:\n" + json.dumps(numbered, ensure_ascii=False)
    )

    try:
        resp = requests.post(
            CLAUDE_API_URL,
            headers={
                "x-api-key": api_key,
                "anthropic-version": "2023-06-01",
                "content-type": "application/json",
            },
            json={
                "model": model,
                "max_tokens": MAX_TOKENS,
                "messages": [
                    {"role": "user", "content": prompt},
                    {"role": "assistant", "content": "["},
                ],
            },
            timeout=timeout,
        )
        if resp.status_code >= 400:
            print(f"[translate] HTTP {resp.status_code}: {resp.text[:300]}")
            return [None] * len(texts)
        body = resp.json()
        stop_reason = body.get("stop_reason")
        text = body["content"][0]["text"].strip()
        if text.startswith("```"):
            text = text.split("```", 2)[1]
            if text.startswith("json"):
                text = text[4:]
            text = text.strip()
        if not text.startswith("["):
            text = "[" + text
        try:
            arr = json.loads(text)
        except json.JSONDecodeError as exc:
            if stop_reason == "max_tokens":
                print(
                    "[translate] response cut off by max_tokens "
                    f"(MAX_TOKENS={MAX_TOKENS}); raise TRANSLATE_MAX_TOKENS "
                    "or translate fewer items per call."
                )
            else:
                print(f"[translate] could not parse JSON: {exc}")
            return [None] * len(texts)
    except Exception as exc:  # network, timeout, etc.
        print(f"[translate] call failed: {exc}")
        return [None] * len(texts)

    # Map by id back into a dense list.
    out: list[Optional[str]] = [None] * len(texts)
    if isinstance(arr, list):
        for obj in arr:
            try:
                i = int(obj["id"])
                ja = obj.get("ja")
                if 0 <= i < len(out) and isinstance(ja, str) and ja.strip():
                    out[i] = ja.strip()
            except (KeyError, TypeError, ValueError):
                continue
    return out
