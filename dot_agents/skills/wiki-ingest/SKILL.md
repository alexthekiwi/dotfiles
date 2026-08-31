---
name: wiki-ingest
description: Ingest an already identified source file or URL into The Caretakers Obsidian wiki. Use when the user supplies the source or asks to preserve and summarize specific client material. For a meeting identified only by recency, date, client, person, or context, MUST load ingest-meeting first and never search for the transcript manually. Copies raw evidence, updates client-domain pages and indexes, and records the manifest.
---

# Wiki Ingest

Use this skill to turn client source material into durable wiki context. Preserve raw evidence first, then write short useful pages that future agents can find quickly.

## First Steps
0. When a meeting request lacks an exact transcript path, load `ingest-meeting` and follow it through transcript, vault, and domain confirmation. Resume this workflow only after that skill has selected all three.

1. Read `references/caretakers-vault.md`.
2. Resolve the client slug from the current working directory, user text, or an existing domain folder.
3. Run the helper:

```bash
python3 ~/.agents/skills/wiki-ingest/scripts/wiki_ingest.py prepare --source "<source-path>" --slug "<client-slug>"
```

If `prepare` reports `already_ingested: true` and the user did not ask to force re-ingest, stop and report the existing manifest entry.

For a URL, fetch it first with the browser/web tools, save the cleaned source into a temporary Markdown file, then run `prepare` on that file.

## Ingest Workflow

1. Read the copied raw source completely unless it is too large; for very large sources, read the summary first, then search/read the relevant transcript sections.
2. Read `hot.md`, `index.md`, the client `domains/<slug>/_index.md`, and only the specific existing pages that may be updated.
3. Create or update a source page under `domains/<slug>/sources/` for meetings, briefs, transcripts, screenshots, and other source artifacts.
4. Update existing spec, decision, concept, entity, or domain pages when the source changes the working context. Do not create new pages for every passing mention.
5. Update the client `_index.md` with active work, key technical context, sources, decisions, or open questions.
6. Update root `index.md` only when the domain summary or catalog has materially changed.
7. Add a concise entry near the top of `hot.md` when the information is likely useful in the next few sessions.
8. Prepend an entry to `log.md` for every ingest.
9. Record the manifest entry after all pages are written:

```bash
python3 ~/.agents/skills/wiki-ingest/scripts/wiki_ingest.py record \
  --raw-rel ".raw/<client-slug>/<file>" \
  --hash "<hash-from-prepare>" \
  --created "domains/<client-slug>/sources/<Source Page>.md" \
  --updated "domains/<client-slug>/_index.md" \
  --updated "hot.md" \
  --updated "log.md"
```

## Source Page Shape

Use this frontmatter pattern and adjust fields only when useful:

```markdown
---
type: source
title: "Client - Source Title YYYY-MM-DD"
source_type: meeting-transcript
date: YYYY-MM-DD
domain: client-slug
created: YYYY-MM-DD
updated: YYYY-MM-DD
tags:
  - client-slug
  - source
  - meeting
status: evergreen
related:
  - "[[Client Domain Page]]"
---

# Client - Source Title YYYY-MM-DD

One-paragraph description. Include participants, purpose, and raw path.

## Action items

**Alex:**
- [ ] Concrete item

**Client:**
- [ ] Concrete item

## Key takeaways

- Durable point that affects future work.
```

Prefer synthesis over transcription. Link to the raw file instead of duplicating long transcript text.

## Editorial Rules

- Treat `.raw/` source files as immutable after copying. Only `.raw/.manifest.json` is maintained by the ingest process.
- Do not write under `~/Library/Mobile Documents/iCloud~md~obsidian/`.
- Do not scaffold a new client domain without user confirmation unless the user explicitly asked for a new domain.
- Do not silently overwrite contradictions. Add a short contradiction or open-question note and link both pages.
- Keep pages compact. If a page is becoming a dumping ground, create a focused source/spec/concept page and link it.
- Prefer existing pages and terminology over new abstractions.
- Keep client-sensitive commercial details in the relevant client domain, and avoid promoting sensitive internal-only details into broad root summaries unless already present there.

## Output

Finish with the created/updated pages and the key follow-up items. Mention if a source was skipped because the manifest showed it was unchanged.
