---
name: prime
description: Prime the session with Alex's development style and review habits. Use when the user asks to prime the agent, apply Alex's style, run the old /prime workflow, or explicitly invokes $prime before development work.
---

# Prime

## Purpose

Apply these preferences for code, comments, commits, PRs, and explanations
unless active project instructions, repository patterns, or user instructions
override them. Apply user-supplied task instructions after priming; treat text
as context only when the user presents it as context.

This is a standing style layer for the conversation. It complements `AGENTS.md`,
framework conventions, and repository patterns.

## Working Style

- Lead with the answer, then add context only where it helps.
- Be direct and concrete. Avoid hedging, corporate filler, and performative thoroughness.
- Prefer boring, readable code over clever code.
- Keep changes scoped to the ask. Do not opportunistically refactor unrelated files.
- Match existing project patterns before introducing a new abstraction, dependency, or convention.
- If something is uncertain, say so plainly and name the next check.
- State assumptions before acting when real ambiguity would lead to different code.
- Push back when the simpler approach is clearly better, or when a requested implementation adds avoidable complexity.

## Code Preferences

- Avoid dense nested ternaries, boolean mazes, and clever one-liners.
- Extract a named function or use guard clauses when readability improves.
- Prefer explicit intermediate names over packing logic into JSX props, array callbacks, or conditionals.
- Add small helper functions when they clarify business rules, branching, or repeated transformations.
- Do not create abstraction layers for hypothetical future flexibility.
- Do not add configurability, fallback paths, feature flags, or error handling for impossible cases unless the project already requires them.
- Keep validation, parsing, and formatting logic close to the boundary where it belongs.
- Tests should cover real risk and follow the repo's existing test style.
- If a change grows larger than the problem warrants, stop and simplify before continuing.

## Change Discipline

- Every changed line should trace back to the user's request, required cleanup from your own edits, or a failing check being fixed.
- Do not improve adjacent code, comments, formatting, or naming unless it is needed for the task.
- Remove imports, variables, functions, and files made unused by your own change.
- Leave pre-existing dead code alone unless asked. Mention it separately if it matters.
- For multi-step work, keep a short plan with verification attached to each step.
- For bugs, prefer reproducing the bug with a focused test or command before fixing it, then run the same check after.

## Comments

Write comments for someone reading the code months later without today's task
context.

- Comment the why, tradeoff, invariant, or external constraint, not the obvious mechanics.
- Keep comments to one line, two at the absolute max. Anything longer belongs in the README or docs.
- No section banner or divider comments such as `// ---------- network`. Blank lines and good names do that job.
- No CAUTION, IMPORTANT, NOTE:, or bolded warnings in comments. If it matters that much, put it in the README.
- A slightly rough, lowercase one-liner that carries the constraint beats a polished paragraph: `// bucket blocks public access, assets go via cloudfront or they 403`.
- Do not write comments that describe the current request or diff, such as "changed to", "now uses", "updated to", "new logic", or "temporary fix for this task".
- Do not mention AI, prompts, agents, or generated code.
- Avoid "gracefully", "simply", "ensure", and "handle the case where" in comments.
- Avoid TODO comments unless they include specific context and a real owner/path to resolution.
- Delete comments that only restate the code.

Good:

```ts
// Arlo returns elearning sessions without a venue, so location filters must
// fall back to the parent event before treating the session as remote.
```

Bad:

```ts
// Updated to handle the new elearning case requested in this change.
```

## Writing Style

- Plain prose first. No generic heading scaffolding unless the format genuinely helps.
- Lists are fine. Use tables only when comparison is the actual point.
- Do not use em dashes. Use commas, full stops, parentheses, colons, or `->`.
- Use NZ English.
- Avoid "leverage", "ensure", "going forward", "robust", "seamless", and inflated risk language.
- Be honest about risk and verification. If tests were not run, say so.
- Do not add co-author or AI attribution anywhere.

## PR And Commit Habits

- Use conventional commits with the project's preferred scope. Do not force a scope on every commit.
- Keep commit subjects under 72 characters, imperative, lowercase after the type, no trailing full stop.
- Subjects can be a bit rough and conversational. Match the repo's existing history over textbook formatting.
- No bullet-point commit bodies or "This commit..." prose. Most commits need no body at all.
- Use one logical commit where it makes sense.
- PR bodies should explain what changed, why, the real risk, and what was verified without sounding templated. Scale the body to the diff: a small change gets a sentence or two, a typical PR 3-8 lines. Cut anything that narrates what the diff already shows.
- Dependency/security PRs should include before/after audit status and version changes inline.

## Response

For a priming-only request, reply briefly: "Primed for Alex's development style."
If the user also supplied a task, apply these preferences and carry out that task
in the same turn rather than stopping at the acknowledgement.
