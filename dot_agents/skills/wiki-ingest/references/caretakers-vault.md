# Caretakers Client Wiki Reference

## Vault

Use:

```text
/Users/alex/Obsidian/caretakers-brain/Wiki
```

This path is the vault root. Current files live directly under it:

- `.raw/`
- `domains/`
- `hot.md`
- `index.md`
- `log.md`
- `overview.md`

Do not assume a nested `wiki/` directory. Some older manifest entries may still contain `wiki/...`; leave old entries alone and use actual vault-relative paths for new entries.

Never write to:

```text
~/Library/Mobile Documents/iCloud~md~obsidian/
```

## Slug Routing

When the CWD is under `~/Code/<project>`, map to a client slug:

| Project directory or alias | Client slug |
| --- | --- |
| `dollarforschools`, `dfs` | `dollar-for-schools` |
| `starinsure-portal`, `star` | `star-insure` |
| `nzscm` | `nzscm` |
| `housies` | `housies` |
| `impac` | `impac` |
| `numberworksnwords`, `nww` | `nww` |
| `karen-farley`, `karen` | `karen-farley` |
| anything else | directory name, normalized to lowercase hyphen-case |

Before writing, confirm `domains/<slug>/` exists. If it does not exist, ask before scaffolding a new domain.

## Reading Order

For client work, read in this order:

1. `hot.md`
2. `index.md`
3. `domains/<slug>/_index.md`
4. Specific pages found from those files or `rg`

Avoid reading large unrelated sections of the wiki. Search first, then open only the relevant pages.

## Common Page Locations

- Domain hub: `domains/<slug>/_index.md`
- Source evidence: `domains/<slug>/sources/*.md`
- People/entities: use existing `people/` or `entities/` folder if present; match the domain's local pattern.
- Concepts/specs/decisions: use existing folders if present; otherwise place focused pages in the domain root unless the domain already has a stronger convention.
- Raw source: `.raw/<slug>/<YYYY-MM-DD>-<short-slug>.<ext>`

## Log Entry Template

Prepend entries to `log.md`:

```markdown
## [YYYY-MM-DD] ingest | Client — Source title
- Source: `.raw/<slug>/<file>`
- Summary: [[Source Page]]
- Pages created: [[Page 1]]
- Pages updated: [[Page 2]], [[Page 3]]
- Key insight: One sentence explaining what changed.
```

## Hot Cache Guidance

Update `hot.md` when the source affects active work, open questions, current quotes, recent incidents, or near-term implementation. Keep entries concise but concrete: the next agent should know what to do without reopening the transcript.
