# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## New Machine Setup

### 1. Install dependencies

```bash
brew install neovim lazygit ripgrep fd fzf node tmux thefuck rmtrash
brew install --cask font-jetbrains-mono-nerd-font
brew install chezmoi
```

### 2. Install oh-my-zsh and powerlevel10k

```bash
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k
```

### 3. Apply dotfiles

```bash
chezmoi init --apply alexthekiwi
```

This pulls and applies: zsh config, git config, tmux config, neovim (LazyVim), iTerm2 preferences, and the tmux-sessionizer script.

### 4. Open neovim

```bash
nvim
```

First launch will bootstrap Lazy and install all plugins automatically. Wait for it to finish.

### 5. iTerm2 preferences

In iTerm2: **Preferences > General > Preferences**

- Check **Load preferences from a custom folder or URL**
- Set path to `~/.config/iterm2`
- Check **Save changes to folder when iTerm2 quits**

## Syncing Changes

### Pull latest from another machine

```bash
chezmoi update
```

### After editing a config locally

```bash
# Add the changed file
chezmoi add ~/.tmux.conf

# Push
chezmoi cd
git add . && git commit -m "update tmux config" && git push
exit
```

### Quick diff of local vs chezmoi

```bash
chezmoi diff
```

## Safer interactive `rm`

`~/.local/bin/rm` is on the PATH in `.zshrc`. It blocks the literal targets
`$HOME`, `$HOME/`, `/`, `/Users`, and `/Users/` (exit 64), then forwards all
other arguments to Homebrew's `rmtrash`, which moves files into macOS Trash.
Install `rmtrash` on each Mac before using the wrapper.

This is a guard against common typos, not a sandbox: other path spellings,
absolute `/bin/rm`, and programs that don't use the interactive shell's PATH
can still delete files permanently.

## Agent Skills

The laptop is the primary development machine; the homelab is backup development and household media infrastructure.

- `~/.agents/skills/`: canonical shared development skills, including scripts and references. Claude skill entries are relative symlinks to these copies; Codex and Cursor read this directory natively, so there are no `~/.codex/skills` links. OMP discovers the shared root directly.
- `~/.agents/AGENTS.md`: shared operating preferences, linked into Codex's and Claude's global instruction locations. OMP reads it directly.
- `~/.agents/pstack-omp/`: links to the omp subset of pstack, loaded only by omp (`skills.customDirectories`). `~/.agents/vendor/pstack` is a pinned archive external (`.chezmoiexternal.toml`); Claude Code and Cursor use pstack's own plugin.
- `~/.agents/optional/pocock/`: Matt Pocock's skills, opt-in through the `c-greenfield` alias and `~/.omp/agent/overlays/greenfield.yml`. omp overlays replace arrays, so the overlay repeats `pstack-omp`.
- `~/.omp/agent/skills/qbit-seed-cleanup/`: homelab-only, with Claude/Codex links to that source. `.chezmoiignore` excludes it on hosts other than `homelab`; its service helpers and credentials remain local.

These directories deliberately do not use chezmoi's `exact_` attribute. Extra machine-only skills, plugin-managed skills, and `.codex/skills/.system` are left alone. Avoid using rsync to replace managed skill trees after this cutover.

### Editing a shared skill

Edit the canonical copy, then capture only that skill:

```bash
chezmoi add ~/.agents/skills/<name>
chezmoi diff ~/.agents/skills/<name>
```

Review and commit the corresponding `dot_agents/skills/<name>` changes in this repository. Skill packages can contain credentials as well as example tokens: review secret-scanner warnings before committing. SiteHost reads credentials from the environment or local `~/.config/sitehost/credentials.env` (mode 0600); that file is explicitly ignored and must be provisioned separately on each machine.

### First adoption on an existing machine

Compare existing skills before applying, especially same-named copies that differ. Back up local copies outside this repository before replacing directories with symlinks. The homelab's pre-cutover copies are under `~/.local/state/skill-migration/`.

Use a scoped apply, keeping repository install scripts and unrelated configuration out of the migration:

```bash
chezmoi diff ~/.agents ~/.claude/skills ~/.claude/CLAUDE.md \
  ~/.codex/agents ~/.codex/AGENTS.md ~/.omp/agent/overlays
chezmoi --less-interactive apply --exclude scripts \
  ~/.agents ~/.claude/skills ~/.claude/CLAUDE.md \
  ~/.codex/agents ~/.codex/AGENTS.md ~/.omp/agent/overlays
```

On the homelab, also apply `~/.omp/agent/skills`. At a conflicting local skill, choose `diff` or `skip` until the local edits have been reconciled; do not use `--force` or `all-overwrite` for initial adoption. The laptop's shared skills and global preferences were reconciled with the homelab on 2026-09-07. Its previous Gemini/OpenClaw copies are backed up outside this repository under `~/.local/state/skill-audit/`.

Gemini and opencode were removed on 2026-10-18, and OpenClaw on 2026-10-20. Other machine-local and vendor-managed skills remain untouched.

The 2026-09-07 audit retired `arrange`, whose instruction body duplicated `layout` and which Impeccable already marked as renamed. Use `impeccable layout` (the standalone command skills were folded into `impeccable` on 2026-10-18); `.chezmoiremove` removes the old canonical directory and Claude/Codex entries. The laptop's pre-audit copy is preserved alongside the provider backups.

### Homelab cleanup safety

`qbit-seed-cleanup preview` is not read-only: it reconciles tracker tags. A request to audit torrents alone does not authorise that write. The skill requires approval before invoking it for inspection. The cleanup keeps `deleteFiles=false` and checks payload retention, but a hardlink count alone does not prove the second link is inside a media library.

## Tmux Cheat Sheet

| Action                    | Keys                          |
| ------------------------- | ----------------------------- |
| Prefix                    | `Ctrl+Space`                      |
| Fuzzy-find project session| `Ctrl+Space` then `f`             |
| Split pane vertically     | `Ctrl+Space` then `\|`            |
| Split pane horizontally   | `Ctrl+Space` then `-`             |
| Move between panes        | `Alt+arrow keys` (no prefix)      |
| New window (tab)          | `Ctrl+Space` then `c`             |
| Next/prev window          | `Ctrl+Space` then `n` / `p`       |
| Kill pane                 | `Ctrl+Space` then `x`             |
| Kill session              | `Ctrl+Space` then `:kill-session` |
| Detach from session       | `Ctrl+Space` then `d`             |
| List sessions             | `tmux ls`                     |

## What's Included

- `~/.zshrc` — shell config with oh-my-zsh + powerlevel10k
- `~/.gitconfig` — git config with delta diff viewer
- `~/.tmux.conf` — tmux config with sensible defaults
- `~/.config/nvim/` — LazyVim neovim config
- `~/.config/iterm2/` — iTerm2 preferences
- `~/.local/bin/tmux-sessionizer` — fuzzy project session switcher
