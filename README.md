# Dotfiles

Managed with [chezmoi](https://www.chezmoi.io/).

## New Machine Setup

### 1. Install dependencies

```bash
brew install neovim lazygit ripgrep fd fzf node tmux thefuck
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
