#!/usr/bin/env bash
# =============================================================================
# install.sh -- Arch Linux package bootstrap for Niri + Noctalia + Cybersec
# Run: chmod +x install.sh && ./install.sh
# =============================================================================
set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
BLU='\033[0;34m'
YLW='\033[1;33m'
CYN='\033[0;36m'
BLD='\033[1m'
RST='\033[0m'

info()  { echo -e "${BLU}[*]${RST} $*"; }
ok()    { echo -e "${GRN}[+]${RST} $*"; }
warn()  { echo -e "${YLW}[!]${RST} $*"; }
fail()  { echo -e "${RED}[-]${RST} $*"; exit 1; }

banner() {
  echo -e "${CYN}"
  cat << 'EOF'
    _   ___      _   _  __         __       ___
   / | / (_)____(_) / |/ /___  ___/ /_____ / (_)___ _
  /  |/ / / ___/ / /    / __ \/ __/ __/ _ `/ / / _ `/
 / /|  / / /  / / / /| / /_/ / /_/ /_/ /_,/ / / \_,_/
/_/ |_/_/_/  /_/ /_/ |_\____/\__/\__/\__,_/_/_/\__,_/
EOF
  echo -e "${RST}"
  echo -e "${BLD}Arch Linux + BlackArch -- Niri + Noctalia + Cybersec${RST}"
  echo -e "${CYN}$(printf '%.0s-' {1..52})${RST}"
  echo ""
}

# ── Require Arch ───────────────────────────────────────────────────────────
[[ -f /etc/arch-release ]] || fail "This script is for Arch Linux only."

banner

# ── AUR helper ─────────────────────────────────────────────────────────────
if command -v yay &>/dev/null; then
  AUR="yay"
elif command -v paru &>/dev/null; then
  AUR="paru"
else
  info "Installing yay (AUR helper) ..."
  sudo pacman -S --needed --noconfirm base-devel git
  tmpdir=$(mktemp -d)
  git clone https://aur.archlinux.org/yay-bin.git "$tmpdir/yay-bin"
  (cd "$tmpdir/yay-bin" && makepkg -si --noconfirm)
  rm -rf "$tmpdir"
  AUR="yay"
fi
ok "AUR helper: $AUR"

# ── BlackArch repository ──────────────────────────────────────────────────
if ! pacman -Sl blackarch &>/dev/null; then
  info "Adding BlackArch repository ..."
  tmpdir=$(mktemp -d)
  curl -sL https://blackarch.org/strap.sh -o "$tmpdir/strap.sh"
  chmod +x "$tmpdir/strap.sh"
  sudo "$tmpdir/strap.sh"
  rm -rf "$tmpdir"
  sudo pacman -Sy
  ok "BlackArch repo added."
else
  ok "BlackArch repo already present."
fi

# ── Package lists ──────────────────────────────────────────────────────────

# Core Wayland / Niri / Noctalia
PKG_CORE=(
  niri
  noctalia-shell
  xwayland-satellite
  swww
  fuzzel
  swaylock
  swayidle
  wl-clipboard
  cliphist
  brightnessctl
  polkit-gnome
  xdg-desktop-portal-gnome
  xdg-utils
  qt5-wayland
  qt6-wayland
  grim
  slurp
  wlogout
  swaybg
  mako
  wev
)

# Terminal / Shell / Prompt
PKG_SHELL=(
  kitty
  tmux
  zsh
  starship
  fzf
  fd
  ripgrep
  eza
  bat
  zoxide
  direnv
  jq
  yq
  tree
  btop
  fastfetch
  less
  man-db
)

# Fonts / Theming
PKG_FONTS=(
  ttf-jetbrains-mono-nerd
  noto-fonts
  noto-fonts-cjk
  noto-fonts-emoji
  papirus-icon-theme
)

# Development
PKG_DEV=(
  neovim
  git
  git-delta
  lazygit
  github-cli
  base-devel
  cmake
  gcc
  gdb
  lldb
  clang
  rust
  go
  python
  python-pip
  python-virtualenv
  nodejs
  npm
  docker
  docker-compose
  podman
  stow
  editorconfig-core-c
  stylua
  shfmt
  prettierd
)

# Cybersecurity / Pentesting
PKG_SEC=(
  nmap
  masscan
  rustscan
  wireshark-qt
  tcpdump
  netcat
  socat
  openbsd-netcat
  bind
  whois
  traceroute
  curl
  wget
  nikto
  sqlmap
  hydra
  john
  hashcat
  aircrack-ng
  burpsuite
  metasploit
  gobuster
  feroxbuster
  ffuf
  dirb
  enum4linux
  smbclient
  smbmap
  exploitdb
  binwalk
  foremost
  steghide
  perl-image-exiftool
  radare2
  ghidra
  checksec
  python-pwntools
  impacket
  responder
  proxychains-ng
  tor
  openvpn
  wireguard-tools
  net-tools
  arp-scan
  nbtscan
  dnsrecon
  subfinder
  amass
  httpx
  nuclei
  volatility3
  python-pycryptodome
  strace
  ltrace
)

# BlackArch tools (from blackarch repo)
PKG_BLACKARCH=(
  # ── Recon / OSINT ──────────────────────────────────────────────────────
  blackarch-recon
  theharvester
  sherlock
  maltego
  spiderfoot
  recon-ng
  photon
  osrframework
  whatweb
  wafw00f
  dnsrecon
  fierce
  sublist3r
  assetfinder
  hakrawler
  gau
  waybackurls
  katana

  # ── Web exploitation ───────────────────────────────────────────────────
  blackarch-webapp
  wpscan
  xsser
  commix
  dalfox
  arjun
  paramspider
  jwt-tool
  graphqlmap
  nosqlmap

  # ── Exploitation frameworks ────────────────────────────────────────────
  blackarch-exploitation
  exploitdb
  searchsploit
  routersploit
  crackmapexec
  evil-winrm
  covenant
  sliver

  # ── Password attacks ───────────────────────────────────────────────────
  blackarch-cracker
  hashcat-utils
  hcxtools
  hcxdumptool
  cewl
  crunch
  medusa
  patator
  thc-pptp-bruter

  # ── Wireless ───────────────────────────────────────────────────────────
  blackarch-wireless
  bettercap
  wifite
  pixiewps
  reaver
  hostapd-mana
  fluxion
  airgeddon

  # ── Privilege escalation / post-exploitation ───────────────────────────
  blackarch-exploitation
  linpeas
  winpeas
  pspy
  linenum
  linux-exploit-suggester
  mimikatz
  bloodhound
  sharphound
  rubeus
  chisel
  ligolo-ng

  # ── Reversing / binary ─────────────────────────────────────────────────
  blackarch-reversing
  rizin
  cutter
  iaito
  retdec
  angr
  ropper
  one_gadget
  patchelf

  # ── Forensics ──────────────────────────────────────────────────────────
  blackarch-forensic
  autopsy
  bulk-extractor
  scalpel
  yara
  volatility3
  pdf-parser
  oletools
  exiftool

  # ── Networking / MITM ──────────────────────────────────────────────────
  blackarch-networking
  bettercap
  mitmproxy
  ettercap
  arpspoof
  tcpreplay
  hping
  ncrack
  proxychains-ng
  chisel
  socat

  # ── Social engineering ─────────────────────────────────────────────────
  blackarch-social
  social-engineer-toolkit
  gophish
  king-phisher
  evilginx2

  # ── Crypto ─────────────────────────────────────────────────────────────
  blackarch-crypto
  hashpump
  rsactftool
  featherduster
  python-pycryptodome
  xortool

  # ── Stego ──────────────────────────────────────────────────────────────
  blackarch-stego
  stegseek
  zsteg
  stegsolve
  openstego
  snow

  # ── Fuzzing ────────────────────────────────────────────────────────────
  blackarch-fuzzer
  afl
  afl++
  boofuzz
  radamsa
  zzuf

  # ── Misc / utility ─────────────────────────────────────────────────────
  seclists
  wordlistctl
  webshells
  cyberchef
  pwncat
)

# ── Install ────────────────────────────────────────────────────────────────
install_pkgs() {
  local label="$1"; shift
  local pkgs=("$@")
  info "Installing ${BLD}$label${RST} (${#pkgs[@]} packages) ..."
  $AUR -S --needed --noconfirm "${pkgs[@]}" 2>/dev/null || {
    warn "Batch install had failures; retrying individually ..."
    for pkg in "${pkgs[@]}"; do
      $AUR -S --needed --noconfirm "$pkg" 2>/dev/null || warn "  skip: $pkg"
    done
  }
  ok "$label done."
  echo ""
}

install_pkgs "Core (Niri / Noctalia / Wayland)" "${PKG_CORE[@]}"
install_pkgs "Shell & CLI tools"                 "${PKG_SHELL[@]}"
install_pkgs "Fonts & Theming"                   "${PKG_FONTS[@]}"
install_pkgs "Development"                       "${PKG_DEV[@]}"
install_pkgs "Cybersecurity"                     "${PKG_SEC[@]}"
install_pkgs "BlackArch"                         "${PKG_BLACKARCH[@]}"

# ── Set default shell ──────────────────────────────────────────────────────
if [[ "$SHELL" != */zsh ]]; then
  info "Setting zsh as default shell ..."
  chsh -s "$(which zsh)"
  ok "Default shell set to zsh (re-login to activate)."
fi

# ── Enable services ────────────────────────────────────────────────────────
info "Enabling system services ..."
sudo systemctl enable --now NetworkManager  2>/dev/null || true
sudo systemctl enable --now bluetooth       2>/dev/null || true
sudo systemctl enable --now docker          2>/dev/null || true
sudo usermod -aG docker    "$USER"          2>/dev/null || true
sudo usermod -aG wireshark "$USER"          2>/dev/null || true

# ── Zinit (zsh plugin manager) ─────────────────────────────────────────────
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [[ ! -d "$ZINIT_HOME" ]]; then
  info "Installing Zinit (zsh plugin manager) ..."
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
  ok "Zinit installed."
fi

# ── Wordlists ──────────────────────────────────────────────────────────────
if [[ ! -d /usr/share/seclists ]]; then
  info "SecLists not found at /usr/share/seclists, checking for package ..."
  $AUR -S --needed --noconfirm seclists 2>/dev/null || warn "  seclists not available as package"
fi
if [[ ! -f /usr/share/wordlists/rockyou.txt ]]; then
  if [[ -f /usr/share/wordlists/rockyou.txt.gz ]]; then
    info "Decompressing rockyou.txt ..."
    sudo gzip -dk /usr/share/wordlists/rockyou.txt.gz
    ok "rockyou.txt ready."
  fi
fi

# ── Screenshots dir ────────────────────────────────────────────────────────
mkdir -p ~/Pictures/Screenshots

echo ""
echo -e "${CYN}$(printf '%.0s-' {1..52})${RST}"
ok "Installation complete."
echo ""
info "Next steps:"
info "  1. Run ${BLD}./deploy.sh${RST} to symlink configs into place."
info "  2. Log out, select ${BLD}niri${RST} from your display manager."
info "  3. Press ${BLD}Super+Return${RST} to open a terminal."
info "  4. Run ${BLD}nvim${RST} -- plugins install automatically on first launch."
echo ""
