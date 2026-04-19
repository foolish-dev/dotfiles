-- =============================================================================
-- Autocommands
-- =============================================================================
local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- ── Highlight on yank ─────────────────────────────────────────────────────
autocmd("TextYankPost", {
  group = augroup("YankHighlight", { clear = true }),
  callback = function()
    (vim.hl or vim.highlight).on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- ── Restore cursor position ───────────────────────────────────────────────
autocmd("BufReadPost", {
  group = augroup("RestoreCursor", { clear = true }),
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lcount = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lcount then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- ── Auto-resize splits on terminal resize ─────────────────────────────────
autocmd("VimResized", {
  group = augroup("AutoResize", { clear = true }),
  callback = function() vim.cmd("tabdo wincmd =") end,
})

-- ── Close specific buffers with q ─────────────────────────────────────────
autocmd("FileType", {
  group = augroup("CloseWithQ", { clear = true }),
  pattern = { "help", "man", "qf", "lspinfo", "startuptime", "checkhealth" },
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = ev.buf, silent = true })
  end,
})

-- ── Filetype overrides ───────────────────────────────────────────────────
autocmd("FileType", {
  group = augroup("IndentOverrides", { clear = true }),
  pattern = { "lua", "nix", "yaml", "json", "html", "css", "javascript", "typescript", "typescriptreact" },
  callback = function()
    vim.opt_local.shiftwidth  = 2
    vim.opt_local.tabstop     = 2
    vim.opt_local.softtabstop = 2
  end,
})

-- ── Recognize security-related filetypes ──────────────────────────────────
autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup("SecurityFiletypes", { clear = true }),
  pattern = { "*.nse", "*.rules" },
  callback = function(ev)
    if ev.match:match("%.nse$") then
      vim.bo[ev.buf].filetype = "lua"
    elseif ev.match:match("%.rules$") then
      vim.bo[ev.buf].filetype = "conf"
    end
  end,
})

-- ── Auto-open Neo-tree + opencode on startup ──────────────────────────────
-- Skip when launched bare so the alpha dashboard still shows.
autocmd("VimEnter", {
  group = augroup("AutoOpenLayout", { clear = true }),
  callback = function()
    if vim.fn.argc() == 0 then return end
    vim.schedule(function()
      vim.cmd("Neotree show")
      pcall(function() require("opencode").toggle() end)
      vim.cmd("wincmd p") -- return focus to the file window
    end)
  end,
})
