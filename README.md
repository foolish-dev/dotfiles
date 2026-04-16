# dotfiles -- Arch Linux / Niri / Noctalia / Cybersec

Personal dotfiles for a scrollable-tiling Wayland desktop built for coding and security work.

## Stack

| Layer | Tool |
|---|---|
| Compositor | [Niri](https://github.com/YaLTeR/niri) (scrollable tiling, Wayland) |
| Desktop Shell | [Noctalia](https://github.com/noctalia-dev/noctalia-shell) (bar, dock, panels, notifications, lock screen) |
| Terminal | Kitty |
| Shell | Zsh + Zinit + Starship |
| Editor | Neovim (lazy.nvim, 16 LSP servers, DAP, Treesitter) |
| Launcher | Fuzzel |
| Theme | Tokyo Night (dark, transparent) |

## Quick Start

```bash
git clone https://github.com/foolish-dev/dotfiles.git ~/dotfiles
cd ~/dotfiles
chmod +x install.sh deploy.sh
./install.sh    # Arch only -- installs 100+ packages via yay
./deploy.sh     # symlinks configs into ~/.config/
```

First `nvim` launch auto-installs all plugins and LSP servers.

## Layout

```
.config/
  niri/config.kdl           # compositor keybinds, layout, window rules
  noctalia/
    settings.json            # bar, dock, panels, launcher settings
    colors.json              # Tokyo Night material colors
  nvim/
    init.lua                 # lazy.nvim bootstrap
    lua/config/              # options, keymaps, autocmds
    lua/plugins/             # colorscheme, treesitter, lsp, editor, ui, coding
  kitty/kitty.conf           # terminal (0.92 opacity, Tokyo Night)
  fuzzel/fuzzel.ini           # app launcher
  starship.toml              # prompt
  systemd/user/              # noctalia-shell, cliphist, swww services
.zshrc                       # shell config with 60+ security aliases
install.sh                   # Arch package bootstrap
deploy.sh                    # symlink deployer with auto-backup
```

## Keybinds (Niri)

| Key | Action |
|---|---|
| `Super+Return` | Terminal |
| `Super+D` | Launcher |
| `Super+B` | Firefox |
| `Super+N` | Neovim |
| `Super+H/J/K/L` | Focus window |
| `Super+1-9` | Workspace |
| `Super+F` | Maximize |
| `Super+Q` | Close window |
| `Super+V` | Clipboard history |
| `Super+Escape` | Lock screen |
| `Super+Ctrl+M` | msfconsole |
| `Super+Ctrl+W` | Wireshark |
| `Super+Ctrl+B` | Burp Suite |
| `Super+Ctrl+T` | btop |
| `Print` | Screenshot |

## Neovim

- **LSP**: pyright, ruff, clangd, rust_analyzer, gopls, zls, ts_ls, bashls, lua_ls, html, cssls, jsonls, yamlls, dockerls, terraformls, tailwindcss
- **DAP**: Python (debugpy), C/C++/Rust (GDB)
- **Plugins**: Telescope, Neo-tree, Gitsigns, Trouble, Bufferline, Lualine, Noice, nvim-cmp, LuaSnip, Conform (format-on-save), hex.nvim, rest.nvim, toggleterm
- **Leader**: `Space`
- `<leader>ff` find files, `<leader>fg` grep, `<leader>t` file tree, `<leader>xH` hex editor

## Zsh Security Toolkit

```bash
revshell 10.10.14.1 4444    # generate bash/python/nc/powershell reverse shells
listen 4444                  # nc listener
serve 8000                   # python HTTP server
recon example.com            # whois + DNS summary
quickscan 10.10.10.0/24     # ping sweep
hashid <hash>                # identify hash type
nmap-stealth 10.10.10.1     # SYN scan, fragmented, padded
msf                          # msfconsole -q
```

## License

MIT
