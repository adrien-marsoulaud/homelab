#!/bin/bash
# Bootstrap script — runs once on first `chezmoi apply`
# Installs all tools and configures the environment from scratch.

set -e
echo "🏠 Bootstrapping homelab..."

# ─── Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "→ Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi

# ─── System packages ─────────────────────────────────────────────────────────
echo "→ Installing system packages..."
sudo apt-get update -q
sudo apt-get install -y -q \
  zsh curl git build-essential \
  tmux ripgrep \
  fonts-firacode
# NB: fzf is deliberately NOT installed via apt. Ubuntu ships 0.44.x, which
# lacks `fzf --zsh` (0.48+), and it would shadow the git checkout below.

# ─── Brew packages ───────────────────────────────────────────────────────────
# Installed one at a time: a single unavailable formula must not abort the whole
# bootstrap. Failures are collected and reported at the end instead.
echo "→ Installing brew packages..."
BREW_FAILED=()

# mvnd is not in homebrew-core — it ships from the mvnd project's own tap.
# Homebrew refuses formulae from untrusted taps, so trust it explicitly.
# mvnd@1 is the stable 1.x line (embeds Maven 3.9.x); plain mvnd is the 2.x
# preview (embeds Maven 4.0.x).
if ! brew tap | grep -q '^mvndaemon/mvnd$'; then
  echo "→ Tapping mvndaemon/mvnd..."
  brew tap mvndaemon/mvnd
fi
brew trust mvndaemon/mvnd

for formula in \
  chezmoi \
  git-delta \
  eza \
  gh \
  mise \
  direnv \
  mvndaemon/mvnd/mvnd@1; do
  if brew list --formula "${formula##*/}" &>/dev/null; then
    echo "  ✓ ${formula##*/} already installed"
  elif brew install "$formula"; then
    echo "  ✓ ${formula##*/}"
  else
    echo "  ✗ ${formula##*/} failed" >&2
    BREW_FAILED+=("$formula")
  fi
done

# ─── WezTerm ─────────────────────────────────────────────────────────────────
if ! command -v wezterm &>/dev/null; then
  echo "→ Installing WezTerm..."
  curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --dearmor -o /usr/share/keyrings/wezterm-fury.gpg
  echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' \
    | sudo tee /etc/apt/sources.list.d/wezterm.list
  sudo apt-get update -q && sudo apt-get install -y wezterm
fi

# ─── Zsh as default shell ────────────────────────────────────────────────────
if [ "$SHELL" != "$(which zsh)" ]; then
  echo "→ Setting zsh as default shell..."
  chsh -s "$(which zsh)"
fi

# ─── Oh My Zsh ───────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  echo "→ Installing Oh My Zsh..."
  # KEEP_ZSHRC=yes is essential: without it the installer replaces ~/.zshrc
  # with its own template, silently discarding the one chezmoi just applied
  # (which is what selects the powerlevel10k theme and sources ~/.p10k.zsh).
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi

# ─── Powerlevel10k ───────────────────────────────────────────────────────────
if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]; then
  echo "→ Installing Powerlevel10k..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
fi

# ─── Zsh plugins ─────────────────────────────────────────────────────────────
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  echo "→ Installing zsh-autosuggestions..."
  git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions \
    "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  echo "→ Installing zsh-syntax-highlighting..."
  git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting \
    "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ─── Sublime Text ────────────────────────────────────────────────────────────
if ! command -v subl &>/dev/null; then
  echo "→ Installing Sublime Text..."
  sudo snap install sublime-text --classic
fi

# ─── fzf ─────────────────────────────────────────────────────────────────────
if [ ! -d "$HOME/.fzf" ]; then
  echo "→ Installing fzf..."
  git clone --depth=1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  # --no-update-rc: ~/.zshrc is chezmoi-managed and already sources ~/.fzf.zsh,
  # so letting the installer append to it just creates drift on every run.
  "$HOME/.fzf/install" --all --no-bash --no-fish --no-update-rc
fi

# ─── FiraCode Nerd Font ───────────────────────────────────────────────────────
if ! fc-list | grep -qi "FiraCode Nerd Font"; then
  echo "→ Installing FiraCode Nerd Font..."
  mkdir -p "$HOME/.local/share/fonts"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.tar.xz" \
    | tar -xJ -C "$HOME/.local/share/fonts"
  fc-cache -fv
fi

# ─── mise tools ──────────────────────────────────────────────────────────────
# The tool list lives in ~/.config/mise/config.toml, which chezmoi applies
# before this script runs. `mise install` with no arguments installs exactly
# what that file declares.
#
# It used to run `mise install <tool>` per tool, which downloads a version but
# never selects one — so everything except node (pinned in config.toml) was
# installed yet absent from PATH.
if command -v mise &>/dev/null; then
  echo "→ Installing mise tools..."
  mise install
fi

# ─── Snap apps ───────────────────────────────────────────────────────────────
echo "→ Installing snap apps..."
snap list localsend &>/dev/null || sudo snap install localsend
snap list vlc &>/dev/null       || sudo snap install vlc

# ─── 1Password ───────────────────────────────────────────────────────────────
if ! command -v 1password &>/dev/null; then
  echo "→ Installing 1Password..."
  curl -sS https://downloads.1password.com/linux/keys/1password.asc \
    | sudo gpg --dearmor --output /usr/share/keyrings/1password-archive-keyring.gpg
  echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/1password-archive-keyring.gpg] https://downloads.1password.com/linux/debian/amd64 stable main' \
    | sudo tee /etc/apt/sources.list.d/1password.list
  sudo apt-get update -q && sudo apt-get install -y 1password
fi

# ─── LibreOffice ─────────────────────────────────────────────────────────────
if ! command -v libreoffice &>/dev/null; then
  echo "→ Installing LibreOffice..."
  sudo apt-get install -y libreoffice-writer libreoffice-calc
fi

# ─── Claude Desktop (official Anthropic build) ───────────────────────────────
if ! command -v claude-desktop &>/dev/null; then
  echo "→ Installing Claude Desktop..."
  sudo curl -fsSLo /usr/share/keyrings/claude-desktop-archive-keyring.asc \
    https://downloads.claude.ai/claude-desktop/key.asc
  echo "deb [signed-by=/usr/share/keyrings/claude-desktop-archive-keyring.asc] https://downloads.claude.ai/claude-desktop/apt/stable stable main" \
    | sudo tee /etc/apt/sources.list.d/claude-desktop.list
  sudo apt-get update -q && sudo apt-get install -y claude-desktop
fi

# ─── GNOME extensions ────────────────────────────────────────────────────────
# Skipped entirely when there's no GNOME session (server, container, other DE).
if command -v gnome-extensions &>/dev/null && command -v gnome-shell &>/dev/null; then
  D2P_UUID="dash-to-panel@jderose9.github.com"

  if [ ! -d "$HOME/.local/share/gnome-shell/extensions/$D2P_UUID" ]; then
    echo "→ Installing Dash to Panel..."
    # Query e.g.o for the build matching THIS shell version rather than pinning
    # a version that will stop resolving after a distro upgrade.
    shell_ver=$(gnome-shell --version | awk '{print $3}' | cut -d. -f1)
    d2p_path=$(curl -fsS "https://extensions.gnome.org/extension-info/?pk=1160&shell_version=${shell_ver}" \
      | jq -r '.download_url // empty')
    if [ -n "$d2p_path" ]; then
      tmp_zip=$(mktemp --suffix=.zip)
      curl -fsSL "https://extensions.gnome.org${d2p_path}" -o "$tmp_zip" \
        && gnome-extensions install --force "$tmp_zip"
      rm -f "$tmp_zip"
    else
      echo "  ✗ no Dash to Panel build for GNOME Shell ${shell_ver} — skipping" >&2
    fi
  fi

  # `gnome-extensions enable` fails until the running shell rescans, which on
  # Wayland means a full re-login. Setting the key directly takes effect at the
  # next login either way.
  if [ -d "$HOME/.local/share/gnome-shell/extensions/$D2P_UUID" ]; then
    gsettings set org.gnome.shell enabled-extensions "['$D2P_UUID']"
    # Ubuntu Dock and Dash to Panel both manage a dock; running both gives two.
    # Ubuntu enables its dock via the session mode, so it must be turned off
    # through disabled-extensions rather than by editing enabled-extensions.
    gsettings set org.gnome.shell disabled-extensions "['ubuntu-dock@ubuntu.com']"
  fi
fi

# ─── git-bash-prompt ─────────────────────────────────────────────────────────
if [ ! -d "$HOME/.bash-git-prompt" ]; then
  echo "→ Installing bash-git-prompt..."
  git clone --depth=1 https://github.com/magicmonty/bash-git-prompt.git "$HOME/.bash-git-prompt"
fi

echo ""
if [ "${#BREW_FAILED[@]}" -gt 0 ]; then
  echo "⚠️  Homelab bootstrap finished, but these brew formulae failed:"
  printf '   - %s\n' "${BREW_FAILED[@]}"
else
  echo "✅ Homelab bootstrap complete!"
fi
echo "→ Restart your terminal or run: exec zsh"
