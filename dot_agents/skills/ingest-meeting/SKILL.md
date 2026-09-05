---
name: ingest-meeting
description: Route loosely identified meeting requests through transcript discovery and then wiki-ingest. MUST use this skill before wiki-ingest when the user identifies a meeting by recency, date, client, person, or context without supplying an exact transcript path, including requests such as "ingest my latest Di Antonio meeting" or "add yesterday's meeting to the wiki". Finds MacWhisper JSON and text exports for Alex or Keir and supports shared or project-specific wikis.
---

# Ingest Meeting

Turn a loosely identified meeting into a confirmed source for `wiki-ingest`. Keep discovery read-only; do not copy or modify anything until the user confirms the operator, meeting, and wiki.

## 1. Confirm the operator

Infer `alex` or `keir` from the explicit request, known user identity, OS account, or home directory. Ask for confirmation even when the inference is strong:

> I’ll use Alex’s meeting exports. Is that right?

If neither identity is supported, ask which operator to use. Do not silently inspect both users' folders.

## 2. Find candidate transcripts

Resolve the meetings root in this order:

1. An explicit path from the user.
2. `$HOME/Library/CloudStorage/SynologyDrive-Caretakers/meetings`.
3. A matching `SynologyDrive-Caretakers/meetings` directory under `$HOME/Library/CloudStorage`.

Run the bundled discovery helper, passing the user's full request as the query so it can remove workflow words and retain client/person clues:

```bash
python3 <skill-dir>/scripts/find_meetings.py \
  --operator alex \
  --query "ingest my latest Di Antonio meeting" \
  --limit 3
```

Use `--root` when the resolved meetings root differs from the default. The helper:

- scans only the confirmed operator's directory;
- ignores audio files;
- groups formats belonging to the same recording;
- prefers `.json` over `.txt` when both exist;
- ranks candidates by hint matches and recording recency;
- returns recording timestamps, excerpts, and alternative formats as JSON.

If no transcript is present, explain that MacWhisper may not have completed auto-export and stop. If the user supplied a hint but none of the candidates match it, say so rather than presenting a recency-only result as a confident match.

Present at most three useful candidates with recording date/time, format, a short contextual excerpt, and why each matched. Ask for selection when multiple candidates plausibly match or the user's intent is unclear. Reuse an exact source selection already supplied by the user. Never select or ingest an `.m4a` file when a transcript exists.

## 3. Confirm the destination wiki

Reuse a destination explicitly supplied by the user or already confirmed in this task. Otherwise ask the user to choose from these options, recommending the default:

1. **Default (Synology Shared Wiki)** — resolve `$HOME/Obsidian/caretakers-brain/Wiki`, falling back to `$HOME/Library/CloudStorage/SynologyDrive-Caretakers/brain/wiki`.
2. **Current Project Directory** — inspect the current project for its wiki root and local `AGENTS.md`; if more than one plausible wiki exists, ask which one.
3. **Somewhere Else (Specify)** — ask for an absolute path.

Do not assume the current project is the destination merely because the command was run there. Resolve the selected path, verify it exists, and read its root `AGENTS.md` completely when present.

## 4. Resolve the client or domain

Use the user's hint, transcript contents, and existing wiki domains/pages to identify the destination domain. Prefer an existing normalized slug, such as `diantonio`, over creating a new spelling. Confirm ambiguous results. Do not scaffold a missing domain without explicit approval.

Use the recording timestamp embedded in the filename as the meeting date. Fall back to the file modification time only when no recording timestamp is available.

## 5. Delegate to wiki-ingest

Load and follow the installed `wiki-ingest` skill after the source, vault, and domain are confirmed. If `wiki-ingest` is unavailable, stop and explain that dependency instead of inventing a parallel ingest process. Pass the selected vault explicitly to its helper:

```bash
python3 <wiki-ingest-dir>/scripts/wiki_ingest.py prepare \
  --source "<confirmed-transcript>" \
  --slug "<confirmed-domain>" \
  --vault "<confirmed-vault>" \
  --date "<recording-date>"
```

Use the same `--vault` value when recording the manifest entry. If the selected wiki does not use the Caretakers `.raw/`, `domains/`, manifest, and index conventions, follow its local `AGENTS.md` while preserving the `wiki-ingest` principles: retain immutable raw evidence, create a concise source page, update relevant durable context, and record the ingest according to that wiki's conventions. Do not force the shared-wiki layout onto another wiki.

Prefer the JSON transcript because it retains speaker grouping. Treat speaker identities as unknown unless the transcript provides multiple strong contextual anchors. In synthesis, write `Speaker 2 (likely Name)` when useful and supported; otherwise preserve `Speaker 1`, `Speaker 2`, and so on. Never alter the raw transcript to replace speaker labels.

## 6. Report the result

Finish with:

- the operator and transcript selected;
- the destination vault and domain;
- pages created or updated by `wiki-ingest`;
- material action items or unresolved speaker ambiguity;
- whether a duplicate was skipped by the manifest.
