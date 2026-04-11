#!/usr/bin/env bash
#
# Dotfiles Installer
# A full-featured dotfiles management system with backup, symlinks, and profiles
#
# Usage: ./install.sh [options] [modules...]
#
set -euo pipefail

# =============================================================================
# CONFIGURATION
# =============================================================================

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$DOTFILES_DIR/backups/$(date +%Y%m%d_%H%M%S)"
CONFIG_FILE="$DOTFILES_DIR/dotfiles.conf"
LOG_FILE="$DOTFILES_DIR/install.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Defaults
DRY_RUN=false
VERBOSE=false
FORCE=false
BACKUP=true
PROFILE=""
SELECTED_MODULES=()

# =============================================================================
# LOGGING
# =============================================================================

log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    case "$level" in
        INFO)  echo -e "${BLUE}[*]${NC} $message" ;;
        OK)    echo -e "${GREEN}[+]${NC} $message" ;;
        WARN)  echo -e "${YELLOW}[!]${NC} $message" ;;
        ERROR) echo -e "${RED}[-]${NC} $message" ;;
        DEBUG) $VERBOSE && echo -e "${MAGENTA}[D]${NC} $message" ;;
    esac
}

info()  { log INFO "$@"; }
ok()    { log OK "$@"; }
warn()  { log WARN "$@"; }
error() { log ERROR "$@"; }
debug() { log DEBUG "$@"; }

# =============================================================================
# HELPERS
# =============================================================================

banner() {
    echo -e "${CYAN}"
    cat << 'EOF'
    ____        __  _____ __         
   / __ \____  / /_/ __(_) /__  _____
  / / / / __ \/ __/ /_/ / / _ \/ ___/
 / /_/ / /_/ / /_/ __/ / /  __(__  ) 
/_____/\____/\__/_/ /_/_/\___/____/  
                                     
EOF
    echo -e "${NC}"
    echo -e "${BOLD}Dotfiles Installer v1.0${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
}

usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS] [MODULES...]

Options:
    -h, --help          Show this help message
    -n, --dry-run       Show what would be done without making changes
    -v, --verbose       Enable verbose output
    -f, --force         Force overwrite without prompting
    -b, --no-backup     Don't backup existing files
    -p, --profile NAME  Use specific profile (e.g., work, home, server)
    -l, --list          List available modules
    -u, --uninstall     Remove symlinks and restore backups
    -s, --status        Show current installation status
    --packages          Also install system packages

Modules:
    all         Install all modules
    shell       Shell configurations (bash, zsh)
    editor      Editor configurations (vim, neovim)
    terminal    Terminal tools (tmux, starship, alacritty)
    git         Git configuration
    bin         Custom scripts and binaries

Examples:
    $(basename "$0")                    # Install all modules
    $(basename "$0") shell git          # Install specific modules
    $(basename "$0") -p work all        # Install with 'work' profile
    $(basename "$0") -n all             # Dry run to see changes
    $(basename "$0") -u shell           # Uninstall shell module

EOF
}

confirm() {
    local message="$1"
    local default="${2:-y}"
    
    if $FORCE; then
        return 0
    fi
    
    local prompt
    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    else
        prompt="[y/N]"
    fi
    
    read -rp "$(echo -e "${YELLOW}$message $prompt${NC} ")" response
    response=${response:-$default}
    
    [[ "$response" =~ ^[Yy]$ ]]
}

command_exists() {
    command -v "$1" &> /dev/null
}

detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    elif [[ -f /etc/redhat-release ]]; then
        echo "redhat"
    elif [[ -f /etc/arch-release ]]; then
        echo "arch"
    else
        echo "unknown"
    fi
}

detect_shell() {
    basename "$SHELL"
}

# =============================================================================
# BACKUP & SYMLINK FUNCTIONS
# =============================================================================

backup_file() {
    local file="$1"
    
    if [[ -e "$file" ]] && [[ ! -L "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_path="$BACKUP_DIR/$(basename "$file")"
        
        if $DRY_RUN; then
            info "[DRY RUN] Would backup: $file -> $backup_path"
        else
            cp -r "$file" "$backup_path"
            debug "Backed up: $file -> $backup_path"
        fi
    fi
}

create_symlink() {
    local source="$1"
    local target="$2"
    
    # Expand ~ in target
    target="${target/#\~/$HOME}"
    
    # Create parent directory if needed
    local parent_dir=$(dirname "$target")
    if [[ ! -d "$parent_dir" ]]; then
        if $DRY_RUN; then
            info "[DRY RUN] Would create directory: $parent_dir"
        else
            mkdir -p "$parent_dir"
            debug "Created directory: $parent_dir"
        fi
    fi
    
    # Handle existing file/symlink
    if [[ -e "$target" ]] || [[ -L "$target" ]]; then
        if [[ -L "$target" ]]; then
            local current_link=$(readlink "$target")
            if [[ "$current_link" == "$source" ]]; then
                debug "Symlink already correct: $target"
                return 0
            fi
        fi
        
        if $BACKUP; then
            backup_file "$target"
        fi
        
        if $DRY_RUN; then
            info "[DRY RUN] Would remove: $target"
        else
            rm -rf "$target"
        fi
    fi
    
    # Create symlink
    if $DRY_RUN; then
        info "[DRY RUN] Would link: $source -> $target"
    else
        ln -sf "$source" "$target"
        ok "Linked: $(basename "$source") -> $target"
    fi
}

remove_symlink() {
    local target="$1"
    target="${target/#\~/$HOME}"
    
    if [[ -L "$target" ]]; then
        if $DRY_RUN; then
            info "[DRY RUN] Would remove symlink: $target"
        else
            rm "$target"
            ok "Removed symlink: $target"
        fi
    fi
}

# =============================================================================
# MODULE INSTALLATION
# =============================================================================

install_shell() {
    info "Installing shell configurations..."
    
    local shell_dir="$DOTFILES_DIR/shell"
    
    # Bash
    [[ -f "$shell_dir/bashrc" ]] && create_symlink "$shell_dir/bashrc" "~/.bashrc"
    [[ -f "$shell_dir/bash_profile" ]] && create_symlink "$shell_dir/bash_profile" "~/.bash_profile"
    [[ -f "$shell_dir/bash_aliases" ]] && create_symlink "$shell_dir/bash_aliases" "~/.bash_aliases"
    
    # Zsh
    [[ -f "$shell_dir/zshrc" ]] && create_symlink "$shell_dir/zshrc" "~/.zshrc"
    [[ -f "$shell_dir/zshenv" ]] && create_symlink "$shell_dir/zshenv" "~/.zshenv"
    [[ -f "$shell_dir/zprofile" ]] && create_symlink "$shell_dir/zprofile" "~/.zprofile"
    
    # Common
    [[ -f "$shell_dir/aliases" ]] && create_symlink "$shell_dir/aliases" "~/.aliases"
    [[ -f "$shell_dir/functions" ]] && create_symlink "$shell_dir/functions" "~/.functions"
    [[ -f "$shell_dir/exports" ]] && create_symlink "$shell_dir/exports" "~/.exports"
    
    # Profile-specific
    if [[ -n "$PROFILE" ]] && [[ -f "$shell_dir/profile_$PROFILE" ]]; then
        create_symlink "$shell_dir/profile_$PROFILE" "~/.profile_local"
    fi
    
    ok "Shell configurations installed"
}

install_editor() {
    info "Installing editor configurations..."
    
    local editor_dir="$DOTFILES_DIR/editor"
    
    # Vim
    [[ -f "$editor_dir/vimrc" ]] && create_symlink "$editor_dir/vimrc" "~/.vimrc"
    [[ -d "$editor_dir/vim" ]] && create_symlink "$editor_dir/vim" "~/.vim"
    
    # Neovim
    if [[ -d "$editor_dir/nvim" ]]; then
        create_symlink "$editor_dir/nvim" "~/.config/nvim"
    fi
    
    # VS Code (if exists)
    if [[ -d "$editor_dir/vscode" ]]; then
        local vscode_dir
        if [[ "$(detect_os)" == "macos" ]]; then
            vscode_dir="$HOME/Library/Application Support/Code/User"
        else
            vscode_dir="$HOME/.config/Code/User"
        fi
        [[ -f "$editor_dir/vscode/settings.json" ]] && create_symlink "$editor_dir/vscode/settings.json" "$vscode_dir/settings.json"
        [[ -f "$editor_dir/vscode/keybindings.json" ]] && create_symlink "$editor_dir/vscode/keybindings.json" "$vscode_dir/keybindings.json"
    fi
    
    ok "Editor configurations installed"
}

install_terminal() {
    info "Installing terminal configurations..."
    
    local terminal_dir="$DOTFILES_DIR/terminal"
    
    # Tmux
    [[ -f "$terminal_dir/tmux.conf" ]] && create_symlink "$terminal_dir/tmux.conf" "~/.tmux.conf"
    [[ -d "$terminal_dir/tmux" ]] && create_symlink "$terminal_dir/tmux" "~/.tmux"
    
    # Starship
    [[ -f "$terminal_dir/starship.toml" ]] && create_symlink "$terminal_dir/starship.toml" "~/.config/starship.toml"
    
    # Alacritty
    [[ -f "$terminal_dir/alacritty.toml" ]] && create_symlink "$terminal_dir/alacritty.toml" "~/.config/alacritty/alacritty.toml"
    [[ -f "$terminal_dir/alacritty.yml" ]] && create_symlink "$terminal_dir/alacritty.yml" "~/.config/alacritty/alacritty.yml"
    
    # Kitty
    [[ -f "$terminal_dir/kitty.conf" ]] && create_symlink "$terminal_dir/kitty.conf" "~/.config/kitty/kitty.conf"
    
    # WezTerm
    [[ -f "$terminal_dir/wezterm.lua" ]] && create_symlink "$terminal_dir/wezterm.lua" "~/.wezterm.lua"
    
    ok "Terminal configurations installed"
}

install_git() {
    info "Installing git configurations..."
    
    local git_dir="$DOTFILES_DIR/git"
    
    [[ -f "$git_dir/gitconfig" ]] && create_symlink "$git_dir/gitconfig" "~/.gitconfig"
    [[ -f "$git_dir/gitignore_global" ]] && create_symlink "$git_dir/gitignore_global" "~/.gitignore_global"
    [[ -f "$git_dir/gitmessage" ]] && create_symlink "$git_dir/gitmessage" "~/.gitmessage"
    
    # Profile-specific git config
    if [[ -n "$PROFILE" ]] && [[ -f "$git_dir/gitconfig_$PROFILE" ]]; then
        create_symlink "$git_dir/gitconfig_$PROFILE" "~/.gitconfig_local"
    fi
    
    ok "Git configurations installed"
}

install_bin() {
    info "Installing custom scripts..."
    
    local bin_dir="$DOTFILES_DIR/bin"
    local target_bin="$HOME/.local/bin"
    
    mkdir -p "$target_bin"
    
    if [[ -d "$bin_dir" ]]; then
        for script in "$bin_dir"/*; do
            if [[ -f "$script" ]]; then
                create_symlink "$script" "$target_bin/$(basename "$script")"
            fi
        done
    fi
    
    ok "Custom scripts installed"
}

install_config() {
    info "Installing additional configs..."
    
    local config_dir="$DOTFILES_DIR/config"
    
    if [[ -d "$config_dir" ]]; then
        for config in "$config_dir"/*; do
            if [[ -e "$config" ]]; then
                local name=$(basename "$config")
                create_symlink "$config" "~/.config/$name"
            fi
        done
    fi
    
    ok "Additional configs installed"
}

# =============================================================================
# UNINSTALL FUNCTIONS
# =============================================================================

uninstall_shell() {
    info "Uninstalling shell configurations..."
    remove_symlink "~/.bashrc"
    remove_symlink "~/.bash_profile"
    remove_symlink "~/.bash_aliases"
    remove_symlink "~/.zshrc"
    remove_symlink "~/.zshenv"
    remove_symlink "~/.zprofile"
    remove_symlink "~/.aliases"
    remove_symlink "~/.functions"
    remove_symlink "~/.exports"
    remove_symlink "~/.profile_local"
}

uninstall_editor() {
    info "Uninstalling editor configurations..."
    remove_symlink "~/.vimrc"
    remove_symlink "~/.vim"
    remove_symlink "~/.config/nvim"
}

uninstall_terminal() {
    info "Uninstalling terminal configurations..."
    remove_symlink "~/.tmux.conf"
    remove_symlink "~/.tmux"
    remove_symlink "~/.config/starship.toml"
    remove_symlink "~/.config/alacritty/alacritty.toml"
    remove_symlink "~/.config/alacritty/alacritty.yml"
    remove_symlink "~/.config/kitty/kitty.conf"
    remove_symlink "~/.wezterm.lua"
}

uninstall_git() {
    info "Uninstalling git configurations..."
    remove_symlink "~/.gitconfig"
    remove_symlink "~/.gitignore_global"
    remove_symlink "~/.gitmessage"
    remove_symlink "~/.gitconfig_local"
}

uninstall_bin() {
    info "Uninstalling custom scripts..."
    local bin_dir="$DOTFILES_DIR/bin"
    local target_bin="$HOME/.local/bin"
    
    if [[ -d "$bin_dir" ]]; then
        for script in "$bin_dir"/*; do
            if [[ -f "$script" ]]; then
                remove_symlink "$target_bin/$(basename "$script")"
            fi
        done
    fi
}

# =============================================================================
# PACKAGE INSTALLATION
# =============================================================================

install_packages() {
    info "Installing system packages..."
    
    local os=$(detect_os)
    local packages_file="$DOTFILES_DIR/packages/${os}.txt"
    
    if [[ ! -f "$packages_file" ]]; then
        packages_file="$DOTFILES_DIR/packages/common.txt"
    fi
    
    if [[ ! -f "$packages_file" ]]; then
        warn "No packages file found"
        return
    fi
    
    case "$os" in
        macos)
            if command_exists brew; then
                info "Installing Homebrew packages..."
                xargs brew install < "$packages_file"
            else
                warn "Homebrew not installed. Skipping packages."
            fi
            ;;
        debian)
            info "Installing apt packages..."
            sudo apt update
            xargs sudo apt install -y < "$packages_file"
            ;;
        arch)
            info "Installing pacman packages..."
            xargs sudo pacman -S --noconfirm < "$packages_file"
            ;;
        redhat)
            info "Installing dnf packages..."
            xargs sudo dnf install -y < "$packages_file"
            ;;
        *)
            warn "Unknown OS. Skipping package installation."
            ;;
    esac
}

# =============================================================================
# STATUS & LIST
# =============================================================================

show_status() {
    echo -e "${BOLD}Dotfiles Status${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local check_files=(
        "~/.bashrc:shell"
        "~/.zshrc:shell"
        "~/.vimrc:editor"
        "~/.config/nvim:editor"
        "~/.tmux.conf:terminal"
        "~/.config/starship.toml:terminal"
        "~/.gitconfig:git"
    )
    
    for item in "${check_files[@]}"; do
        local file="${item%%:*}"
        local module="${item##*:}"
        file="${file/#\~/$HOME}"
        
        if [[ -L "$file" ]]; then
            local target=$(readlink "$file")
            if [[ "$target" == *"$DOTFILES_DIR"* ]]; then
                echo -e "${GREEN}[LINKED]${NC} $file -> $target"
            else
                echo -e "${YELLOW}[OTHER]${NC}  $file -> $target"
            fi
        elif [[ -e "$file" ]]; then
            echo -e "${YELLOW}[EXISTS]${NC} $file (not a symlink)"
        else
            echo -e "${RED}[MISSING]${NC} $file"
        fi
    done
    
    echo ""
    echo -e "${BOLD}Backups:${NC} $(ls -1 "$DOTFILES_DIR/backups" 2>/dev/null | wc -l) backup sessions"
    echo -e "${BOLD}Profile:${NC} ${PROFILE:-none}"
    echo -e "${BOLD}OS:${NC} $(detect_os)"
    echo -e "${BOLD}Shell:${NC} $(detect_shell)"
}

list_modules() {
    echo -e "${BOLD}Available Modules${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "  ${GREEN}shell${NC}     - Bash and Zsh configurations"
    echo -e "  ${GREEN}editor${NC}    - Vim and Neovim configurations"
    echo -e "  ${GREEN}terminal${NC}  - Tmux, Starship, Alacritty configs"
    echo -e "  ${GREEN}git${NC}       - Git configuration and templates"
    echo -e "  ${GREEN}bin${NC}       - Custom scripts and utilities"
    echo -e "  ${GREEN}config${NC}    - Additional ~/.config files"
    echo ""
    echo -e "  ${CYAN}all${NC}       - Install all modules"
    echo ""
    
    if [[ -d "$DOTFILES_DIR/profiles" ]]; then
        echo -e "${BOLD}Available Profiles${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        for profile in "$DOTFILES_DIR/profiles"/*; do
            if [[ -d "$profile" ]]; then
                echo -e "  ${MAGENTA}$(basename "$profile")${NC}"
            fi
        done
    fi
}

# =============================================================================
# MAIN
# =============================================================================

main() {
    local action="install"
    local install_packages_flag=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                banner
                usage
                exit 0
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -b|--no-backup)
                BACKUP=false
                shift
                ;;
            -p|--profile)
                PROFILE="$2"
                shift 2
                ;;
            -l|--list)
                banner
                list_modules
                exit 0
                ;;
            -u|--uninstall)
                action="uninstall"
                shift
                ;;
            -s|--status)
                banner
                show_status
                exit 0
                ;;
            --packages)
                install_packages_flag=true
                shift
                ;;
            -*)
                error "Unknown option: $1"
                usage
                exit 1
                ;;
            *)
                SELECTED_MODULES+=("$1")
                shift
                ;;
        esac
    done
    
    banner
    
    # Default to all modules if none specified
    if [[ ${#SELECTED_MODULES[@]} -eq 0 ]]; then
        SELECTED_MODULES=("all")
    fi
    
    # Expand 'all' to all modules
    if [[ " ${SELECTED_MODULES[*]} " =~ " all " ]]; then
        SELECTED_MODULES=("shell" "editor" "terminal" "git" "bin" "config")
    fi
    
    info "Dotfiles directory: $DOTFILES_DIR"
    info "Action: $action"
    info "Modules: ${SELECTED_MODULES[*]}"
    [[ -n "$PROFILE" ]] && info "Profile: $PROFILE"
    $DRY_RUN && warn "DRY RUN MODE - No changes will be made"
    echo ""
    
    if ! $FORCE && ! $DRY_RUN; then
        if ! confirm "Continue with $action?"; then
            info "Aborted."
            exit 0
        fi
    fi
    
    echo ""
    
    # Create log file
    mkdir -p "$(dirname "$LOG_FILE")"
    echo "=== Dotfiles $action started at $(date) ===" >> "$LOG_FILE"
    
    # Execute action for each module
    for module in "${SELECTED_MODULES[@]}"; do
        case "$action" in
            install)
                case "$module" in
                    shell)    install_shell ;;
                    editor)   install_editor ;;
                    terminal) install_terminal ;;
                    git)      install_git ;;
                    bin)      install_bin ;;
                    config)   install_config ;;
                    *)        warn "Unknown module: $module" ;;
                esac
                ;;
            uninstall)
                case "$module" in
                    shell)    uninstall_shell ;;
                    editor)   uninstall_editor ;;
                    terminal) uninstall_terminal ;;
                    git)      uninstall_git ;;
                    bin)      uninstall_bin ;;
                    *)        warn "Unknown module: $module" ;;
                esac
                ;;
        esac
    done
    
    # Install packages if requested
    if $install_packages_flag; then
        install_packages
    fi
    
    echo ""
    if $DRY_RUN; then
        ok "Dry run complete. No changes were made."
    else
        ok "Dotfiles $action complete!"
        [[ "$action" == "install" ]] && info "Restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    fi
    
    echo "=== Dotfiles $action finished at $(date) ===" >> "$LOG_FILE"
}

main "$@"
