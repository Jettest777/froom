"""
Shared types and helpers across all collectors.
"""

from __future__ import annotations

import re
from typing import Optional
from pydantic import BaseModel, Field


class NewsItem(BaseModel):
    kind: str = Field(description="signing | trade | injury | presser | rumor | other")
    title: str
    title_ja: Optional[str] = None
    excerpt: str
    excerpt_ja: Optional[str] = None
    sources: list[str]
    reliability: float = 0.7
    team_abbrev: Optional[str] = None
    player_name: Optional[str] = None
    coach_name: Optional[str] = None
    published_at: str  # ISO 8601
    url: Optional[str] = None


def normalise_text(text: str) -> str:
    if not text:
        return ""
    text = re.sub(r"\s+", " ", text).strip()
    text = re.sub(r"https?://\S+", "", text).strip()
    return text


def classify_kind(text: str) -> str:
    t = text.lower()
    # Trade indicators
    if any(k in t for k in ["trade", "traded", "acquir", "deal with"]):
        return "trade"
    # Signing
    if any(k in t for k in ["sign", "signs", "signed", "agree", "agrees", "deal", "extension", "extends"]):
        return "signing"
    # Injury
    if any(k in t for k in ["injur", "ir ", "out for", "ruled out", "concussion", "protocol", "questionable", "doubtful"]):
        return "injury"
    # Presser
    if any(k in t for k in ["presser", "press conference", "told reporters", "said", "told"]):
        return "presser"
    # Rumor / weakly sourced
    if any(k in t for k in ["rumor", "report", "expected", "could", "potentially", "exploring"]):
        return "rumor"
    return "other"
