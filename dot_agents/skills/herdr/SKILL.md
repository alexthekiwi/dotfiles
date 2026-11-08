---
name: herdr
description: Use inside Herdr (HC_TERMINAL_ID or HERDR_ENV=1 is set) when asked to open tabs, spaces, workspaces or panes, start another omp, or check on other agents. Covers the Herdr app (herdr-app + hc) and Herdr TUI (herdr).
---

# Herdr

## Which Herdr

- `HERDR_ENV=1`: you are in a **Herdr TUI** pane. Use `herdr`. Read `herdr --skill` before first use.
- `HC_TERMINAL_ID` set: you are in the **Herdr app** (terminals run in herdr-core). Use `herdr-app` for what Alex sees and `hc` for terminals and agents. Read `herdr-app --skill` and `hc --skill` before first use.
- Both set: the TUI is the inner one; use `herdr`.
- Neither: you are not in Herdr. Say so before driving the app (`herdr-app status` shows whether a window is open).

The installed manuals are current; trust them over this file when they differ. They don't share agents: the app can't see TUI agents and the reverse.

## Alex's conventions

- One agent per task. A new task gets its own tab, named for the task, in the project's existing space or workspace. Look it up first (`herdr-app ls` or `herdr workspace list`); never create a duplicate project space.
- Start omp with argv `["omp", "--approval-mode", "yolo"]`. Launchers don't expand shell aliases, so `c` won't work. For greenfield work Alex may ask for `--config /Users/alex/.omp/agent/overlays/greenfield.yml`.
- Pass a first message only when Alex gave one. Otherwise start omp idle.
- Create tabs and spaces only when asked, and give each a clear name.
- Never steal focus. Alex is usually typing in another tab. In the app, `tab.new`, `space.new` and `terminal.keep` all switch the window to what they create, and there's no option to stop it. So record `herdr-app status` (`.space`, `.tab`) first, and straight after creating, `herdr-app do tab.select --id <that tab>` to put him back. Skip the restore only when he asked to be taken there. TUI: always pass `--no-focus`.
- Never close tabs, spaces or workspaces, or kill agents, that you didn't create unless Alex asks. Closing a tab or space ends its agents. Never stop the app, herdr-core or the TUI server.
- Background helpers (`hc run --bg`, `herdr agent prompt --wait`) only when Alex asks for delegation.
- Machines: `hl` is the homelab. Create spaces there with `--machine hl`. Raw `hc run --on hl omp` fails because `~/.local/bin` isn't on its PATH; use `zsh -lic omp` or `/Users/alex/.local/bin/omp`. App `--argv` launches are fine.

## Herdr app recipes

```sh
herdr-app ls    # space and tab IDs; reuse these, don't guess
back=$(herdr-app status | jq -r .tab)    # where Alex is now

# New omp tab in an existing space, then put Alex back
herdr-app do tab.new --space <space-id> --name "<task>" --folder <repo-or-worktree> \
  --argv '["omp","--approval-mode","yolo"]' [--task "<first message>"]
herdr-app do tab.select --id "$back"

# New project space (only when none exists), then put Alex back
herdr-app do space.new --name <project> --folder <path> [--machine hl] \
  --tab "<task>" --argv '["omp","--approval-mode","yolo"]'
herdr-app do tab.select --id "$back"
```

## Herdr TUI recipes

```sh
herdr workspace list
t=$(herdr tab create --workspace <workspace-id> --label "<task>" --cwd <repo> --no-focus)
p=$(printf '%s\n' "$t" | jq -r .result.root_pane.pane_id)
herdr agent start <name> --kind omp --pane "$p" -- --approval-mode yolo
herdr agent prompt <name> "<first message>"   # only if Alex gave one
```

Agent names match `[a-z][a-z0-9_-]{0,31}`. Use `herdr --machine hl ...` for the homelab.

## Feature worktrees

Ask Alex before creating one. Create it with `git worktree add`, then open it with `space.new --folder <worktree>` (app) or `herdr workspace create --cwd <worktree>` (TUI). In a fresh impac worktree, run `pnpm install --frozen-lockfile` first.
