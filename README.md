# homelab

My personal environment — dotfiles, scripts, Claude Code configs, and everything that makes a machine feel like mine.

## Restore on a new machine

One command:

```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply gh:adrien-marsoulaud/homelab
```

This will:
1. Install chezmoi
2. Clone this repo
3. Run the bootstrap script (installs all tools)
4. Apply all dotfiles

## What's included

| File | Purpose |
|------|---------|
| `~/.zshrc` | Zsh config — OMZ, p10k, aliases, fzf, NVM lazy load |
| `~/.bashrc` | Bash config — history, aliases, cargo |
| `~/.gitconfig` | Git — delta pager, aliases, push/pull/rerere config |
| `~/.gitignore` | Global git ignore |
| `~/.tmux.conf` | Tmux — mouse support |
| `~/.p10k.zsh` | Powerlevel10k prompt config |
| `~/.config/wezterm/wezterm.lua` | WezTerm — font, theme, keybindings, pane config |
| `~/.config/mise/config.toml` | mise — trusted paths |
| `~/.config/gh-dash/config.yml` | gh-dash — GitHub PR dashboard |

## Daily commands

```bash
# Pull latest from GitHub and apply
chezmoi update

# Edit a managed file
chezmoi edit ~/.zshrc

# After manually editing a dotfile, sync it back
chezmoi add ~/.zshrc

# See what would change before applying
chezmoi diff

# Apply changes
chezmoi apply
```

## Tools installed by bootstrap

- **Shell**: zsh, Oh My Zsh, Powerlevel10k, zsh-autosuggestions, zsh-syntax-highlighting
- **Terminal**: WezTerm, FiraCode Nerd Font
- **Git**: delta, gh, git-bash-prompt
- **CLI**: fzf, ripgrep, eza, direnv, tmux, mise
- **Dev**: node, python, java (temurin-21), jq, shellcheck, shfmt, ruff, awscli, actionlint
