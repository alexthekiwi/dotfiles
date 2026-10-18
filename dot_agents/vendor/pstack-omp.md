# pstack on omp (Alex's Mac)

pstack skills (`~/.agents/vendor/pstack/pstack`, pinned at 101b274, v0.15.25, via chezmoi `.chezmoiexternal.toml`) are written for Cursor. On omp, map them like this:
- `Task` → omp's task tool. Subagents `poteto-agent` and `comment-sicko` aren't installed; use the `task`/`opus` agents and paste the brief.
- `AskQuestion` → ask in plain text. Open a todolist → omp's todo tool.
- "Run the **name** skill" or `/name` → read `~/.agents/vendor/pstack/pstack/skills/<name>/SKILL.md` and follow it (user types `/skill:<name>`).
- Model slugs → omit, and use the session model or an omp role such as `@opushigh`. Ignore `pstack-models.mdc` and `setup-pstack`.
- `.cursor/skills/`, `~/.cursor/skills/` → `.agents/skills/`, `~/.agents/skills/`. `.cursor/rules/*.mdc` → `AGENTS.md`.
- Cursor transcripts → `~/.omp/agent/sessions/`. Cursor automations, Bugbot, cloud agents and the PR tool: no equivalent, so say so and skip that step.
- Only a subset is linked, in `~/.agents/pstack-omp/` (omp `skills.customDirectories`; Codex and Cursor don't read it). Don't enable `poteto-mode` by default.
