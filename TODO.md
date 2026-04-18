# TODO

Audit of `foolish-dev/dotfiles` — 2026-04-18. Items are grouped by file/area and
ordered **high → low** impact within each section. Checked boxes are done in
commits that landed alongside this file.

---

## Nvim

### Broken / likely-broken
- [x] `lua/plugins/lsp.lua` — removed deprecated `vim.lsp.with()` handler overrides; hover/sigHelp now pass `{ border = "rounded" }` at the call site.
- [x] `lua/plugins/ui.lua` — dropped Noice overrides for `vim.lsp.util.convert_input_to_markdown_lines` / `stylize_markdown` (both removed in Neovim 0.11).
- [x] `lua/plugins/lsp.lua` — removed deprecated `automatic_installation = true` on mason-lspconfig.
- [ ] `rest.nvim` build is fragile: requires `luarocks-build-treesitter-parser` in the hererocks tree + `tree-sitter` CLI on `$PATH`. Drop the plugin in favour of something simpler or live with it now that `tree-sitter-cli` is pulled in via `install.sh`.
- [ ] **Migration**: the whole `require("lspconfig")[server].setup(...)` framework is deprecated in Neovim 0.11 (`:h lspconfig-nvim-0.11`). Move to `vim.lsp.config(server, {...})` + `vim.lsp.enable(server)` on the next major refactor. Non-urgent — current code still works, just emits one warning on startup.

### Quality / drift
- [x] `lua/plugins/lsp.lua` — `ensure_installed` and `simple_servers` now read from one `servers` list at module top.
- [x] Dropped the redundant `K` → hover mapping (built-in since Neovim 0.10).
- [x] Dropped the `TrimWhitespace` autocmd; `.editorconfig` + built-in editorconfig support handle it.
- [x] `.gitignore` no longer ignores `.config/nvim/lazy-lock.json` — tracked for reproducible plugin versions.

---

## Shell scripts

### install.sh
- [x] Add `tree-sitter-cli` to `PKG_DEV` — `rest.nvim` fails to build without it.
- [x] Drop duplicate `seclists` install (it's already in `PKG_BLACKARCH`).
- [x] Drop `neofetch` from `PKG_SHELL` (archived upstream, `fastfetch` covers it).
- [ ] `install_pkgs()` silences pacman with `2>/dev/null` on both the batch and per-package retry, hiding real errors. Log to `/tmp/install-$label.log` instead.
- [ ] Hexstrike service enable on line 617-618 runs **before** `deploy.sh` drops the unit file. The warning always fires on first run. Either move this into `deploy.sh` or add a guard on the unit file existing.

### deploy.sh
- [x] Summary counts now computed dynamically at the end of the script.
- [ ] `sed -i` on `$ASTRONAUT_DIR/metadata.desktop` + `sudo cp` into package dirs is clobbered by pacman on `sddm-astronaut-theme` upgrades. Either document this or use a user-local theme override path.

### bootstrap.sh
- [x] `cat /etc/os-release | grep …` → `grep ^NAME= /etc/os-release`.

---

## Zsh (`.zshrc`)

### Broken
- [x] LM Studio aliases now use the real `lms` CLI (via `~/.lmstudio/bin`, on `$PATH`). Renamed the GUI alias to `lmsgui`.
- [x] Dropped the `linpeas` curl-and-pipe alias; `linpeas` is already installed from `PKG_BLACKARCH`.
- [x] Greeting now prefers `fastfetch` and falls back to `neofetch` only if it's still around.

### Footguns / shadowing (intentional preference — left alone)
- [ ] `alias cat="bat --paging=never"` / `alias hexdump="xxd"` / `alias dc="docker compose"` — flagged in the audit but kept; tell me if you want these renamed or removed.

---

## Git (`.gitconfig`)

- [x] Set email to `cardoffools@gmail.com`.
- [x] Swapped `credential.helper = store` for `git-credential-libsecret`; added `libsecret` to `install.sh` `PKG_DEV`.
- [x] Re-enabled SSH commit signing (`gpgsign`, `gpg.format = ssh`, `allowedSignersFile`); `~/.ssh/allowed_signers` seeded locally (outside the repo since `.ssh/` keys are globally ignored).

---

## Niri (`config.kdl`)

- [x] Removed duplicate `Mod+Space` launcher toggle — `Mod+D` + `F13` (keyd Super-tap) already cover it.
- [ ] Line 349: comment says "Workspace 5: Security | Workspace 6: Network analysis" but no `window-rule` / `spawn-at-startup` pins apps to those workspaces. Either wire it up or drop the comment.

---

## `.local/bin`

- [x] `proj:40`, `gclone:29`: `exec "$SHELL"` now quoted.
- [x] `wallpaper:44`: dropped the `pkill -USR1 noctalia-shell` signal (Noctalia reloads via file-watch on `colors.json`).
- [ ] `sddm-theme:94`: `sudo sed -i` of a packaged `metadata.desktop` is overwritten on `sddm-astronaut-theme` upgrades. Switch to a user-local approach if possible.

---

## README

- [x] Line 48 + layout tree — neofetch replaced with fastfetch.
- [x] Line 343 "155 pinned apps" → 147 (matches `deploy.sh` and the `.desktop` count).
- [ ] LM Studio section (lines 247-253) — update examples to show the new CLI-based commands and the `lmsgui` rename.

---

## Misc

- [x] `.gitignore_global` now ignores SSH keys (`id_rsa`, `id_ed25519`, etc.), `authorized_keys`, `known_hosts`, `*.gpg`, `*.asc`.
- [x] `sof-firmware` in `install.sh` audio stack (committed as `8c953f1`).
