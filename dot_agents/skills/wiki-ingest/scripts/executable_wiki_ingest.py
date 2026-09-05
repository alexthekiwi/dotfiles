#!/usr/bin/env python3
import argparse
import datetime as dt
import hashlib
import json
import re
import shutil
import sys
from pathlib import Path
from typing import Optional


DEFAULT_VAULT = Path.home() / "Obsidian/caretakers-brain/Wiki"
PROJECT_SLUGS = {
    "dollarforschools": "dollar-for-schools",
    "dfs": "dollar-for-schools",
    "starinsure-portal": "star-insure",
    "star": "star-insure",
    "nzscm": "nzscm",
    "housies": "housies",
    "impac": "impac",
    "numberworksnwords": "nww",
    "nww": "nww",
    "karen-farley": "karen-farley",
    "karen": "karen-farley",
}


def slugify(value: str) -> str:
    value = value.lower()
    value = re.sub(r"[^a-z0-9]+", "-", value)
    return value.strip("-") or "source"


def md5(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def rel(path: Path, root: Path) -> str:
    return path.resolve().relative_to(root.resolve()).as_posix()


def load_manifest(vault: Path) -> dict:
    path = vault / ".raw" / ".manifest.json"
    if not path.exists():
        return {"sources": {}}
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    data.setdefault("sources", {})
    return data


def write_manifest(vault: Path, data: dict) -> None:
    path = vault / ".raw" / ".manifest.json"
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def infer_slug(cwd: Path) -> str:
    try:
        code = (Path.home() / "Code").resolve()
        project = cwd.resolve().relative_to(code).parts[0]
    except Exception:
        project = cwd.name
    return PROJECT_SLUGS.get(project, slugify(project))


def normalize_vault(path: Optional[str]) -> Path:
    return Path(path).expanduser() if path else DEFAULT_VAULT


def make_raw_name(source: Path, slug: str, date: str, raw_name: Optional[str]) -> str:
    if raw_name:
        return raw_name
    stem = slugify(source.stem)
    if stem.startswith(date):
        base = stem
    else:
        base = f"{date}-{stem}"
    suffix = source.suffix.lower() or ".md"
    name = f"{base}{suffix}"
    if len(name) > 120:
        name = f"{date}-{slug}-{hashlib.md5(source.name.encode()).hexdigest()[:8]}{suffix}"
    return name


def command_prepare(args: argparse.Namespace) -> int:
    vault = normalize_vault(args.vault)
    source = Path(args.source).expanduser()
    if not source.exists() or not source.is_file():
        print(f"Source file not found: {source}", file=sys.stderr)
        return 2

    slug = args.slug or infer_slug(Path.cwd())
    domain_dir = vault / "domains" / slug
    if not domain_dir.exists() and not args.allow_new_domain:
        print(
            f"Domain does not exist: {domain_dir}\n"
            "Ask before scaffolding, or rerun with --allow-new-domain if the user explicitly requested it.",
            file=sys.stderr,
        )
        return 3

    date = args.date or dt.date.today().isoformat()
    raw_dir = vault / ".raw" / slug
    raw_dir.mkdir(parents=True, exist_ok=True)
    sources_dir = domain_dir / "sources"
    sources_dir.mkdir(parents=True, exist_ok=True)

    raw_path = raw_dir / make_raw_name(source, slug, date, args.raw_name)
    if source.resolve() != raw_path.resolve():
        shutil.copy2(source, raw_path)

    raw_hash = md5(raw_path)
    raw_rel = rel(raw_path, vault)
    manifest = load_manifest(vault)
    existing = manifest["sources"].get(raw_rel)
    already = bool(existing and existing.get("hash") == raw_hash and not args.force)

    title_base = re.sub(r"^\d{4}-\d{2}-\d{2}-", "", raw_path.stem)
    suggested_title = f"{slug.replace('-', ' ').title()} - {title_base.replace('-', ' ').title()} {date}"
    suggested_page = sources_dir / f"{suggested_title}.md"

    print(
        json.dumps(
            {
                "vault": str(vault),
                "slug": slug,
                "domain_dir": str(domain_dir),
                "sources_dir": str(sources_dir),
                "raw_path": str(raw_path),
                "raw_rel": raw_rel,
                "hash": raw_hash,
                "already_ingested": already,
                "existing_manifest": existing,
                "suggested_source_title": suggested_title,
                "suggested_source_path": str(suggested_page),
            },
            indent=2,
        )
    )
    return 0


def command_record(args: argparse.Namespace) -> int:
    vault = normalize_vault(args.vault)
    manifest = load_manifest(vault)
    entry = {
        "hash": args.hash,
        "ingested_at": args.date or dt.date.today().isoformat(),
        "pages_created": args.created or [],
        "pages_updated": args.updated or [],
    }
    manifest["sources"][args.raw_rel] = entry
    write_manifest(vault, manifest)
    print(json.dumps({args.raw_rel: entry}, indent=2))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Prepare and record Caretakers wiki ingests.")
    sub = parser.add_subparsers(dest="command", required=True)

    prepare = sub.add_parser("prepare", help="Copy a source into .raw/<slug>/ and report ingest metadata.")
    prepare.add_argument("--source", required=True)
    prepare.add_argument("--slug")
    prepare.add_argument("--vault")
    prepare.add_argument("--date")
    prepare.add_argument("--raw-name")
    prepare.add_argument("--force", action="store_true")
    prepare.add_argument("--allow-new-domain", action="store_true")
    prepare.set_defaults(func=command_prepare)

    record = sub.add_parser("record", help="Record completed ingest pages in .raw/.manifest.json.")
    record.add_argument("--raw-rel", required=True)
    record.add_argument("--hash", required=True)
    record.add_argument("--vault")
    record.add_argument("--date")
    record.add_argument("--created", action="append")
    record.add_argument("--updated", action="append")
    record.set_defaults(func=command_record)

    args = parser.parse_args()
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
