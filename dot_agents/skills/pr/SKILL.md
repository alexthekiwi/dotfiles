---
name: pr
description: Stage, commit, push, and open a GitHub pull request in Alex's house style. Use when the user asks to ship current work, create a PR, open a pull request, run the old /pr workflow, or explicitly invokes $pr. Supports draft PRs and issue fallback when requested.
---

# PR

## Workflow

Treat any user-supplied text as optional title/context/flags. If no context is
provided, derive the branch, commit, and PR body from the diff.

Recognised flags:

- `--draft`: open the PR as a draft.
- `--issue`: if `gh pr create` is blocked, file an issue with the diagnosis and patch inline instead of stopping at the failure.

This workflow is standalone. It does not depend on a prior brief, implementation
step, or review step.

## Pre-Flight

1. Confirm the current directory is inside a git repository.
2. Run `git status`. If there is nothing to commit and nothing unpushed, stop with "Nothing to commit".
3. Inspect the diff and recent commits enough to choose the branch name, commit type, scope, and PR title.
4. If the current branch is `main`, `master`, or `production`, create a new branch first.
5. If already on a feature branch, stay on it unless the user explicitly asks for a new branch.

Branch naming:

- Use `fix/` for bugs, `feat/` for features, `refactor/`, `docs/`, `chore/`, or `test` to match the work.
- Use `security/<scope>-<YYYY-MM>` when patching a vulnerability.
- Use `deps/<scope>-<YYYY-MM>` for routine dependency bumps.
- Keep names lowercase, hyphenated, short, and in NZ English where relevant.

## Commit

1. Inspect staged and unstaged changes, then stage only files and hunks belonging to the requested PR. Preserve unrelated work; use explicit paths rather than `git add -A`.
2. Use a conventional commit subject: `type(scope): description`. Do not force a scope on every commit.
3. Keep the subject under 72 characters, imperative, lowercase after the type, no trailing full stop.
4. Subjects can be a bit rough and conversational. Match the repo's existing history over textbook formatting.
5. Do not write commit bodies unless the subject genuinely cannot carry it. Never bullet-point bodies or "This commit..." prose.
6. Use `fix(deps):` for advisory remediation and `chore(deps):` for routine bumps.
7. Never add co-author or AI attribution. Alex is the author.
8. Prefer one logical commit where the diff is one logical change.

## Push And Open

1. Push with `git push -u origin HEAD`.
2. Create the PR with `gh pr create --title "..." --body-file <tmpfile>`.
3. Add `--draft` to `gh pr create` when requested.
4. Write the PR body to a temporary file rather than passing it inline.
5. If PR creation is blocked, open an issue with the diagnosis and patch only when `--issue` or an explicit user instruction authorises that fallback. Otherwise report the blocker with the prepared local result; repository ownership alone does not authorise publishing an issue.

## PR Body Style

Match Alex's writing style, not a template.

Length first: scale the body to the diff, then cut a third. Alex deletes half of most generated PR bodies, so err well short.

- A small single-concern diff gets one or two sentences, no bullets, no sections. That is a complete body, not a lazy one.
- A typical PR is 3-8 lines total including bullets.
- Only go longer when the change genuinely needs explaining (migrations, behaviour changes, anything a reviewer cannot infer from the code).
- Do not narrate the diff. Write only what the code cannot say: the why, the risk, what to check.
- One bullet per meaningful change, never per file. One change means no bullet list at all.
- Skip the risk line, out-of-scope note, and testing note when there is nothing real to say. "Risk is low" on a two-line diff is filler.

Style:

- Lead with the point in plain prose. Say what changed and why.
- For a bug fix, name the symptom and root cause.
- Avoid generic `## Summary`, `## Changes`, `## Testing`, or `## Notes` scaffolding unless the format genuinely helps.
- Use lists, not tables, unless a before/after comparison is the actual point.
- Do not bold every bullet. Use labels sparingly.
- Do not use em dashes. Use commas, full stops, colons, parentheses, or `->`.
- Use NZ English and contractions.
- Avoid corporate filler such as "leverage", "ensure", "going forward", "great", "robust", and inflated risk language.
- Say the real risk honestly.
- Note what is out of scope when that matters.
- Do not use checkbox testing templates. If verification happened, say what ran and what happened. If tests were not run, say so plainly.

Bug-fix shape (only when the fix is big enough to need it):

```markdown
The X endpoint was 500ing with `<error>` (<source/issue ref>). <Root cause in one or two sentences.>

The fix is to <what changed and where>.

What changed:
- <the actual change, one bullet>

Risk is low: <honest one-liner>.
```

Dependency/security PRs:

- Lead with what was bumped and why.
- Include each package and version change inline, for example `symfony/yaml v7.2.6 -> v7.4.12`.
- Include CVE IDs and the reason they matter when available.
- Capture before/after audit counts and confirm the final audit result.
- Mention any test or tooling quirk in one line.
- Note abandoned or out-of-scope packages plainly.

## Output

End with the PR or issue URL and a one-line recap of what landed.
