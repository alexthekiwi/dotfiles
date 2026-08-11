#!/usr/bin/env python3
"""Find and rank recent MacWhisper transcript exports."""

from __future__ import annotations

import argparse
import datetime as dt
import difflib
import getpass
import json
import re
import sys
from pathlib import Path
from typing import Any


FORMAT_PRIORITY = {".json": 4, ".txt": 3, ".md": 2, ".srt": 1, ".vtt": 1}
WORKFLOW_WORDS = {
    "a",
    "add",
    "an",
    "and",
    "call",
    "find",
    "from",
    "ingest",
    "into",
    "last",
    "latest",
    "meeting",
    "most",
    "my",
    "please",
    "recent",
    "the",
    "to",
    "transcript",
    "wiki",
    "yesterday",
}
RECORDING_TIMESTAMP = re.compile(
    r"(?P<date>\d{4}-\d{2}-\d{2})[ _](?P<hour>\d{2})[_:](?P<minute>\d{2})[_:](?P<second>\d{2})"
)
WORD_RE = re.compile(r"[a-z0-9]+")


def default_root() -> Path:
    return Path.home() / "Library" / "CloudStorage" / "SynologyDrive-Caretakers" / "meetings"


def normalize(value: str) -> str:
    return " ".join(WORD_RE.findall(value.lower()))


def compact_with_map(value: str) -> tuple[str, list[int]]:
    characters: list[str] = []
    positions: list[int] = []
    for index, character in enumerate(value.lower()):
        if character.isalnum():
            characters.append(character)
            positions.append(index)
    return "".join(characters), positions


def query_terms(query: str) -> list[str]:
    terms = []
    for term in WORD_RE.findall(query.lower()):
        if term not in WORKFLOW_WORDS and len(term) >= 3 and term not in terms:
            terms.append(term)
    return terms


def json_strings(value: Any) -> list[str]:
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        strings: list[str] = []
        for item in value:
            strings.extend(json_strings(item))
        return strings
    if isinstance(value, dict):
        strings = []
        for item in value.values():
            strings.extend(json_strings(item))
        return strings
    return []


def read_transcript(path: Path) -> str:
    try:
        raw = path.read_text(encoding="utf-8", errors="replace")
    except OSError as error:
        raise RuntimeError(f"Could not read {path}: {error}") from error

    if path.suffix.lower() != ".json":
        return raw

    try:
        return "\n".join(json_strings(json.loads(raw)))
    except json.JSONDecodeError:
        return raw


def recording_time(path: Path) -> tuple[dt.datetime, str]:
    match = RECORDING_TIMESTAMP.search(path.stem)
    if match:
        value = dt.datetime.strptime(
            f"{match.group('date')} {match.group('hour')}:{match.group('minute')}:{match.group('second')}",
            "%Y-%m-%d %H:%M:%S",
        )
        return value, "filename"
    return dt.datetime.fromtimestamp(path.stat().st_mtime), "modified"


def choose_formats(directory: Path) -> list[tuple[Path, list[Path]]]:
    groups: dict[str, list[Path]] = {}
    for path in directory.iterdir():
        if path.is_file() and path.suffix.lower() in FORMAT_PRIORITY:
            groups.setdefault(path.stem.casefold(), []).append(path)

    selected: list[tuple[Path, list[Path]]] = []
    for paths in groups.values():
        ordered = sorted(
            paths,
            key=lambda path: (FORMAT_PRIORITY[path.suffix.lower()], path.stat().st_mtime),
            reverse=True,
        )
        selected.append((ordered[0], ordered[1:]))
    return selected


def locate_match(text: str, terms: list[str]) -> tuple[int | None, list[str]]:
    if not terms:
        return None, []

    lowered = text.lower()
    words = [(match.group(), match.start()) for match in WORD_RE.finditer(lowered)]
    unique_words = {word for word, _ in words}
    matches: list[str] = []
    first_position: int | None = None

    for term in terms:
        exact = lowered.find(term)
        if exact >= 0:
            matches.append(term)
            first_position = exact if first_position is None else min(first_position, exact)
            continue

        close = difflib.get_close_matches(term, unique_words, n=1, cutoff=0.84)
        if close:
            matched_word = close[0]
            position = next(position for word, position in words if word == matched_word)
            matches.append(f"{term}~{matched_word}")
            first_position = position if first_position is None else min(first_position, position)

    compact_query = "".join(terms)
    if len(compact_query) >= 5:
        compact_text, position_map = compact_with_map(text)
        compact_position = compact_text.find(compact_query)
        if compact_position >= 0:
            position = position_map[compact_position]
            if "phrase" not in matches:
                matches.append("phrase")
            first_position = position if first_position is None else min(first_position, position)

    return first_position, matches


def excerpt(text: str, position: int | None, width: int = 280) -> str:
    collapsed = re.sub(r"\s+", " ", text).strip()
    if not collapsed:
        return ""
    if position is None:
        return collapsed[:width]

    original_prefix = text[:position]
    collapsed_position = len(re.sub(r"\s+", " ", original_prefix))
    start = max(0, collapsed_position - width // 3)
    end = min(len(collapsed), start + width)
    snippet = collapsed[start:end].strip()
    return f"…{snippet}" if start else snippet


def candidate(path: Path, alternatives: list[Path], terms: list[str]) -> dict[str, Any]:
    text = read_transcript(path)
    timestamp, timestamp_source = recording_time(path)
    position, matches = locate_match(text, terms)
    age_days = max(0.0, (dt.datetime.now() - timestamp).total_seconds() / 86400)
    recency_score = max(0.0, 100.0 - age_days)
    match_score = len(matches) * 500.0
    if position is not None:
        match_score += 1000.0

    return {
        "path": str(path),
        "format": path.suffix.lower(),
        "recorded_at": timestamp.isoformat(sep=" "),
        "timestamp_source": timestamp_source,
        "age_days": round(age_days, 2),
        "score": round(match_score + recency_score, 2),
        "hint_matched": bool(matches),
        "matches": matches,
        "excerpt": excerpt(text, position),
        "alternative_formats": [str(item) for item in alternatives],
    }


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--operator", default=getpass.getuser(), help="Meeting owner directory, such as alex or keir")
    parser.add_argument("--query", default="", help="The user's meeting description or full ingest request")
    parser.add_argument("--root", type=Path, default=default_root(), help="Parent meetings directory")
    parser.add_argument("--limit", type=int, default=3, help="Maximum candidates to return")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    operator_dir = args.root.expanduser() / args.operator.lower()
    if not operator_dir.is_dir():
        print(json.dumps({"error": f"Meeting directory not found: {operator_dir}"}, indent=2), file=sys.stderr)
        return 2

    terms = query_terms(args.query)
    candidates = []
    errors = []
    for path, alternatives in choose_formats(operator_dir):
        try:
            candidates.append(candidate(path, alternatives, terms))
        except (OSError, RuntimeError) as error:
            errors.append(str(error))

    candidates.sort(key=lambda item: (item["score"], item["recorded_at"]), reverse=True)
    matched = [item for item in candidates if item["hint_matched"]]
    selection_mode = "hint_matches" if terms and matched else "recent_only"
    presented = matched if selection_mode == "hint_matches" else candidates
    output = {
        "operator": args.operator.lower(),
        "directory": str(operator_dir),
        "query": args.query,
        "query_terms": terms,
        "candidate_count": len(candidates),
        "hint_match_count": len(matched),
        "selection_mode": selection_mode,
        "candidates": presented[: max(1, args.limit)],
        "errors": errors,
    }
    print(json.dumps(output, indent=2, ensure_ascii=False))
    return 0 if candidates else 1


if __name__ == "__main__":
    raise SystemExit(main())
