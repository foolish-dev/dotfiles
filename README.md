# dotfiles -- Arch Linux + BlackArch / Niri / Noctalia

Personal dotfiles for a scrollable-tiling Wayland desktop built for coding and offensive security.

## Stack

| Layer | Tool |
|---|---|
| Distro | Arch Linux + [BlackArch](https://blackarch.org) repo |
| Compositor | [Niri](https://github.com/YaLTeR/niri) (scrollable tiling, Wayland) |
| Desktop Shell | [Noctalia](https://github.com/noctalia-dev/noctalia-shell) (bar, dock, panels, notifications, lock screen) |
| Terminal | Kitty |
| Multiplexer | tmux (Ctrl-a prefix, lazygit/btop/fzf popups) |
| Shell | Zsh + Zinit + Starship |
| Editor | Neovim (lazy.nvim, 16 LSP servers, DAP, Treesitter) |
| Git | delta side-by-side diffs, 30+ aliases, lazygit TUI |
| Launcher | Fuzzel |
| Theme | Tokyo Night (dark, transparent) |

## Quick Start

```bash
git clone https://github.com/foolish-dev/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh deploy.sh
./install.sh    # Arch only -- adds BlackArch repo, installs 250+ packages
./deploy.sh     # symlinks all configs into ~/.config/
```

First `nvim` launch auto-installs all plugins and LSP servers.

## Layout

```
.config/
  niri/config.kdl              compositor keybinds, layout, window rules
  noctalia/
    settings.json              bar, dock, panels, launcher settings
    colors.json                Tokyo Night material colors
  nvim/
    init.lua                   lazy.nvim bootstrap
    lua/config/                options, keymaps, autocmds
    lua/plugins/               colorscheme, treesitter, lsp, editor, ui, coding
  kitty/kitty.conf             terminal (0.92 opacity, Tokyo Night)
  tmux/tmux.conf               multiplexer (vim nav, popups, Tokyo Night)
  lazygit/config.yml           git TUI (delta pager, Tokyo Night)
  fuzzel/fuzzel.ini            app launcher
  starship.toml                prompt
  systemd/user/                noctalia-shell, cliphist, swww services
.zshrc                         shell -- 80+ aliases, BlackArch tool shortcuts
.gitconfig                     delta diffs, 30+ aliases, nvim mergetool
.gitignore_global              universal project ignores
.editorconfig                  per-language formatting rules
.local/bin/
  proj                         fuzzy project opener (fzf + tmux)
  mkproj                       scaffold projects (python/rust/go/c/node/shell)
  dev                          3-pane tmux IDE session
  gclone                       smart git clone (gh:user/repo shorthand)
  cheat                        quick reference sheets
install.sh                     Arch + BlackArch package bootstrap
deploy.sh                      symlink deployer with auto-backup
```

## Keybinds

### Niri (compositor)

| Key | Action |
|---|---|
| `Super+Return` | Terminal |
| `Super+D` | Launcher |
| `Super+B` | Firefox |
| `Super+N` | Neovim |
| `Super+H/J/K/L` | Focus window |
| `Super+Shift+H/J/K/L` | Move window |
| `Super+1-9` | Workspace |
| `Super+F` | Maximize |
| `Super+Shift+F` | Fullscreen |
| `Super+Q` | Close window |
| `Super+V` | Clipboard history |
| `Super+Escape` | Lock screen |
| `Super+Ctrl+M` | msfconsole |
| `Super+Ctrl+W` | Wireshark |
| `Super+Ctrl+B` | Burp Suite |
| `Super+Ctrl+T` | btop |
| `Print` | Screenshot |

### Tmux (prefix = Ctrl-a)

| Key | Action |
|---|---|
| `C-a \|` | Split horizontal |
| `C-a -` | Split vertical |
| `C-a h/j/k/l` | Navigate panes |
| `C-a g` | Lazygit popup |
| `C-a b` | btop popup |
| `C-a f` | fzf file opener |
| `C-a c` | New window |
| `C-a Tab` | Last window |
| `C-a S` | New session |

## Neovim

**LSP servers** (auto-installed via Mason):
pyright, ruff, clangd, rust_analyzer, gopls, zls, ts_ls, bashls, lua_ls, html, cssls, jsonls, yamlls, dockerls, terraformls, tailwindcss

**DAP debuggers**: Python (debugpy), C/C++/Rust (GDB)

**Key plugins**: Telescope, Neo-tree, Gitsigns, Trouble, Bufferline, Lualine, Noice, nvim-cmp, LuaSnip, Conform (format-on-save), hex.nvim, rest.nvim, toggleterm, diffview

| Key | Action |
|---|---|
| `<leader>ff` | Find files |
| `<leader>fg` | Live grep |
| `<leader>t` | File tree |
| `<leader>xH` | Hex editor |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Debug continue |
| `<leader>gg` | Git status |
| `<leader>cf` | Format buffer |
| `<leader>xx` | Diagnostics |
| `<C-\>` | Float terminal |

## BlackArch Tools

The installer adds the BlackArch repository and pulls tools across 12 categories:

| Category | Tools |
|---|---|
| Recon/OSINT | theharvester, sherlock, recon-ng, spiderfoot, katana, gau, waybackurls, hakrawler |
| Web | wpscan, commix, dalfox, arjun, jwt-tool, nosqlmap, graphqlmap, paramspider |
| Exploitation | evil-winrm, sliver, routersploit, searchsploit, crackmapexec |
| Passwords | hashcat-utils, hcxtools, cewl, crunch, medusa, patator |
| Wireless | bettercap, wifite, reaver, fluxion, airgeddon |
| Privesc | linpeas, winpeas, pspy, mimikatz, bloodhound, chisel, ligolo-ng |
| Reversing | rizin, cutter, angr, ropper, one_gadget, retdec |
| Forensics | autopsy, yara, bulk-extractor, oletools |
| Social Eng | SET, gophish, evilginx2 |
| Crypto | hashpump, rsactftool, xortool |
| Stego | stegseek, zsteg, stegsolve |
| Fuzzing | afl++, boofuzz, radamsa |

## Zsh Security Toolkit

```bash
# Quick reference
cheat blackarch                    # BlackArch tools overview
cheat privesc                      # Privilege escalation
cheat ad                           # Active Directory attacks
cheat revshells                    # Reverse shell one-liners

# Functions
revshell 10.10.14.1 4444           # Generate bash/python/nc/ps reverse shells
listen 4444                        # nc listener
serve 8000                         # Python HTTP server
recon example.com                  # Whois + DNS summary
quickscan 10.10.10.0/24            # Ping sweep
hashid <hash>                      # Identify hash type

# Dev scripts
proj                               # Fuzzy open a project in tmux
mkproj myapp python                # Scaffold a Python project
dev                                # Launch 3-pane tmux IDE
gclone user/repo                   # Clone from GitHub + cd

# Aliases (samples)
nmap-stealth 10.10.10.1            # SYN scan, fragmented
msf                                # msfconsole -q
wpscan-enum http://target          # WordPress full enum
evilwinrm -i IP -u user -p pass   # WinRM shell
lg                                 # lazygit
```

## License

MIT
