#!/usr/bin/env bash
# =============================================================================
# deploy.sh -- Symlink dotfiles into $HOME
# Run: chmod +x deploy.sh && ./deploy.sh
# =============================================================================
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YLW='\033[1;33m'
RST='\033[0m'

info() { echo -e "${BLU}[*]${RST} $*"; }
ok() { echo -e "${GRN}[+]${RST} $*"; }
warn() { echo -e "${YLW}[!]${RST} $*"; }

BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

link_item() {
  local src="$1"
  local dest="$2"

  # Backup existing files/dirs that are NOT already our symlinks
  if [[ -e "$dest" || -L "$dest" ]]; then
    if [[ "$(readlink -f "$dest" 2>/dev/null)" == "$(readlink -f "$src" 2>/dev/null)" ]]; then
      return # already linked
    fi
    mkdir -p "$BACKUP_DIR"
    local rel="${dest#$HOME/}"
    mkdir -p "$BACKUP_DIR/$(dirname "$rel")"
    mv "$dest" "$BACKUP_DIR/$rel"
    warn "Backed up: ~/$rel -> $BACKUP_DIR/$rel"
  fi

  mkdir -p "$(dirname "$dest")"
  ln -sf "$src" "$dest"
  ok "Linked: $src -> $dest"
}

echo ""
info "=== Deploying dotfiles from $DOTFILES ==="
echo ""

# ── .config directories ───────────────────────────────────────────────────
CONFIG_DIRS=(
  niri
  noctalia
  kitty
  fuzzel
  nvim
  tmux
  lazygit
  "systemd/user"
  opencode
  wal
  neofetch
  gtk-3.0
  gtk-4.0
  qt5ct
  qt6ct
)

for dir in "${CONFIG_DIRS[@]}"; do
  link_item "$DOTFILES/.config/$dir" "$HOME/.config/$dir"
done

# ── Home-level dotfiles ────────────────────────────────────────────────────
link_item "$DOTFILES/.zshrc" "$HOME/.zshrc"
link_item "$DOTFILES/.gitconfig" "$HOME/.gitconfig"
link_item "$DOTFILES/.gitignore_global" "$HOME/.gitignore_global"
link_item "$DOTFILES/.editorconfig" "$HOME/.editorconfig"

# ── Starship config (lives at ~/.config/starship.toml) ─────────────────────
if [[ -f "$DOTFILES/.config/starship.toml" ]]; then
  link_item "$DOTFILES/.config/starship.toml" "$HOME/.config/starship.toml"
fi

# ── Scripts ────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
if [[ -d "$DOTFILES/.local/bin" ]]; then
  for script in "$DOTFILES/.local/bin"/*; do
    [[ -f "$script" ]] && link_item "$script" "$HOME/.local/bin/$(basename "$script")"
  done
fi

# ── Desktop entries (BlackArch tools) ─────────────────────────────────────
mkdir -p "$HOME/.local/share/applications"
if [[ -d "$DOTFILES/.local/share/applications" ]]; then
  info "Deploying BlackArch .desktop entries ..."
  for desktop in "$DOTFILES/.local/share/applications"/*.desktop; do
    [[ -f "$desktop" ]] && link_item "$desktop" "$HOME/.local/share/applications/$(basename "$desktop")"
  done
fi

# ── Wallpapers ─────────────────────────────────────────────────────────────
if [[ -d "$DOTFILES/wallpapers" ]]; then
  info "Deploying wallpapers to ~/Pictures/Wallpapers ..."
  mkdir -p "$HOME/Pictures/Wallpapers"
  for wp in "$DOTFILES/wallpapers"/*; do
    [[ -f "$wp" ]] && link_item "$wp" "$HOME/Pictures/Wallpapers/$(basename "$wp")"
  done
fi

# ── Enable user services ──────────────────────────────────────────────────
info "Enabling user systemd services ..."
systemctl --user daemon-reload 2>/dev/null || true
# These are started by niri spawn-at-startup, so we don't enable them
# as systemd services by default. Uncomment if you prefer systemd management:
# systemctl --user enable --now swww.service 2>/dev/null || true
# systemctl --user enable --now cliphist.service 2>/dev/null || true
systemctl --user enable --now hexstrike-server.service 2>/dev/null ||
  warn "  hexstrike-server.service failed to start (run install.sh first)"

# ── keyd config (Super tap -> F13 for Noctalia launcher) ──────────────────
if [[ -d "$DOTFILES/etc/keyd" ]]; then
  info "Deploying keyd config to /etc/keyd/ ..."
  sudo mkdir -p /etc/keyd
  for conf in "$DOTFILES/etc/keyd"/*; do
    [[ -f "$conf" ]] && sudo cp "$conf" "/etc/keyd/$(basename "$conf")"
    ok "  Copied $(basename "$conf")"
  done
  sudo systemctl enable --now keyd.service 2>/dev/null ||
    warn "  keyd.service failed to start (install keyd first)"
fi

# ── SDDM config (system-wide, requires sudo) ─────────────────────────────
if [[ -d "$DOTFILES/etc/sddm.conf.d" ]]; then
  info "Deploying SDDM config to /etc/sddm.conf.d/ ..."
  sudo mkdir -p /etc/sddm.conf.d
  for conf in "$DOTFILES/etc/sddm.conf.d"/*; do
    [[ -f "$conf" ]] && sudo cp "$conf" "/etc/sddm.conf.d/$(basename "$conf")"
    ok "  Copied $(basename "$conf")"
  done
fi

# ── SDDM theme: upgrade-proof local copy of sddm-astronaut-theme ─────────
# pacman -Syu on `sddm-astronaut-theme` would overwrite our metadata.desktop
# ConfigFile= edit and any file we dropped in Themes/ or Backgrounds/.
# Solve it by copying the theme once into a sibling dir the package does
# not own, then customizing only the copy. Re-run `sudo rm -rf` on the
# local dir + `./deploy.sh` to refresh against upstream theme changes.
ASTRONAUT_SRC="/usr/share/sddm/themes/sddm-astronaut-theme"
ASTRONAUT_DIR="/usr/share/sddm/themes/sddm-astronaut-local"
if [[ -d "$ASTRONAUT_SRC" && -d "$DOTFILES/etc/sddm-themes" ]]; then
  info "Deploying local SDDM astronaut theme copy ..."
  if [[ ! -d "$ASTRONAUT_DIR" ]]; then
    sudo cp -a "$ASTRONAUT_SRC" "$ASTRONAUT_DIR"
    ok "  Created local theme dir: $ASTRONAUT_DIR"
  fi

  for conf in "$DOTFILES/etc/sddm-themes"/*.conf; do
    [[ -f "$conf" ]] || continue
    sudo cp "$conf" "$ASTRONAUT_DIR/Themes/$(basename "$conf")"
    ok "  Copied $(basename "$conf") -> local Themes/"
  done

  # Default SDDM background
  if [[ -f "$DOTFILES/wallpapers/samurai.png" ]]; then
    sudo cp "$DOTFILES/wallpapers/samurai.png" "$ASTRONAUT_DIR/Backgrounds/tokyonight.png"
    ok "  Set default SDDM background: samurai.png"
  fi

  # Point the local copy at the tokyo-night variant
  sudo sed -i 's|^ConfigFile=.*|ConfigFile=Themes/tokyo-night.conf|' "$ASTRONAUT_DIR/metadata.desktop"
  ok "  Activated: tokyo-night variant (in local copy)"
fi

echo ""
ok "=== Deployment complete ==="
echo ""

# Dynamic counts so this summary can't drift from reality.
script_count=$(find "$DOTFILES/.local/bin" -maxdepth 1 -type f 2>/dev/null | wc -l)
desktop_count=$(find "$DOTFILES/.local/share/applications" -maxdepth 1 -name '*.desktop' 2>/dev/null | wc -l)
wallpaper_count=$(find "$DOTFILES/wallpapers" -maxdepth 1 -type f 2>/dev/null | wc -l)
config_list=$(printf '%s,' "${CONFIG_DIRS[@]}" | sed 's/,$//; s|systemd/user|systemd/user|')

info "Summary:"
info "  Configs: ~/.config/{${config_list}}"
info "  Shell:   ~/.zshrc"
info "  Git:     ~/.gitconfig, ~/.gitignore_global"
info "  Editor:  ~/.editorconfig"
info "  Prompt:  ~/.config/starship.toml"
info "  Scripts: ~/.local/bin/ (${script_count} scripts)"
info "  Apps:    ~/.local/share/applications/ (${desktop_count} desktop entries)"
info "  Walls:   ~/Pictures/Wallpapers/ (${wallpaper_count} wallpapers)"
info "  keyd:    /etc/keyd/default.conf (Super tap -> Noctalia launcher)"
info "  SDDM:   /etc/sddm.conf.d/niri.conf + astronaut tokyo-night theme"
info ""
if [[ -d "$BACKUP_DIR" ]]; then
  info "  Backups: $BACKUP_DIR"
fi
echo ""
info "Log out, select 'niri' from SDDM, and log back in."
info "Open a terminal (Super+Return) and run 'nvim' -- plugins install automatically."
echo ""
