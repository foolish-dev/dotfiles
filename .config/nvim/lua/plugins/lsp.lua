-- =============================================================================
-- LSP -- Language servers, completions, snippets
-- =============================================================================
return {
  -- ── Mason: portable LSP / DAP / linter / formatter installer ────────────
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    opts = {
      ui = { border = "rounded", height = 0.7 },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
    },
    opts = {
      ensure_installed = {
        -- Systems / security
        "lua_ls", "pyright", "ruff", "clangd", "rust_analyzer",
        "gopls", "zls",
        -- Web
        "ts_ls", "html", "cssls", "jsonls", "tailwindcss",
        -- Config / ops
        "bashls", "yamlls", "dockerls", "terraformls",
      },
      automatic_installation = true,
    },
  },

  -- ── nvim-lspconfig ──────────────────────────────────────────────────────
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      { "folke/neodev.nvim", opts = {} },
    },
    config = function()
      local lspconfig    = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- Shared on_attach: keymaps set per-buffer when LSP attaches.
      local on_attach = function(_, bufnr)
        local map = function(keys, func, desc)
          vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "LSP: " .. desc })
        end
        map("gd",         vim.lsp.buf.definition,      "Go to definition")
        map("gD",         vim.lsp.buf.declaration,      "Go to declaration")
        map("gr",         vim.lsp.buf.references,       "References")
        map("gi",         vim.lsp.buf.implementation,   "Implementation")
        map("K",          vim.lsp.buf.hover,            "Hover docs")
        map("<C-k>",      vim.lsp.buf.signature_help,   "Signature help")
        map("<leader>rn", vim.lsp.buf.rename,           "Rename")
        map("<leader>ca", vim.lsp.buf.code_action,      "Code action")
        map("<leader>D",  vim.lsp.buf.type_definition,  "Type definition")
        map("<leader>fs", vim.lsp.buf.document_symbol,  "Document symbols")
      end

      -- Servers with default config
      local simple_servers = {
        "pyright", "ruff", "clangd", "rust_analyzer", "gopls", "zls",
        "ts_ls", "html", "cssls", "jsonls", "tailwindcss",
        "bashls", "yamlls", "dockerls", "terraformls",
      }
      for _, server in ipairs(simple_servers) do
        lspconfig[server].setup({
          on_attach    = on_attach,
          capabilities = capabilities,
        })
      end

      -- Lua gets special treatment
      lspconfig.lua_ls.setup({
        on_attach    = on_attach,
        capabilities = capabilities,
        settings = {
          Lua = {
            workspace  = { checkThirdParty = false },
            telemetry  = { enable = false },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim" } },
          },
        },
      })

      -- Diagnostic appearance
      vim.diagnostic.config({
        virtual_text     = { prefix = "" },
        signs            = true,
        underline        = true,
        update_in_insert = false,
        severity_sort    = true,
        float = {
          border = "rounded",
          source = true,
        },
      })

      -- Rounded borders on hover / signature help
      vim.lsp.handlers["textDocument/hover"] =
        vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" })
      vim.lsp.handlers["textDocument/signatureHelp"] =
        vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" })
    end,
  },

  -- ── nvim-cmp: autocompletion engine ─────────────────────────────────────
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      {
        "L3MON4D3/LuaSnip",
        build = "make install_jsregexp",
        dependencies = { "rafamadriz/friendly-snippets" },
        config = function()
          require("luasnip.loaders.from_vscode").lazy_load()
        end,
      },
      "onsails/lspkind.nvim",
    },
    config = function()
      local cmp     = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")

      cmp.setup({
        snippet = {
          expand = function(args) luasnip.lsp_expand(args.body) end,
        },
        window = {
          completion    = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-n>"]     = cmp.mapping.select_next_item(),
          ["<C-p>"]     = cmp.mapping.select_prev_item(),
          ["<C-b>"]     = cmp.mapping.scroll_docs(-4),
          ["<C-f>"]     = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"]     = cmp.mapping.abort(),
          ["<CR>"]      = cmp.mapping.confirm({ select = false }),
          ["<Tab>"]     = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then luasnip.expand_or_jump()
            else fallback() end
          end, { "i", "s" }),
          ["<S-Tab>"]   = cmp.mapping(function(fallback)
            if cmp.visible() then cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then luasnip.jump(-1)
            else fallback() end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip"  },
          { name = "path"     },
        }, {
          { name = "buffer"   },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode      = "symbol_text",
            maxwidth  = 50,
            ellipsis_char = "...",
          }),
        },
      })

      -- Cmdline completions
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources(
          { { name = "path" } },
          { { name = "cmdline" } }
        ),
      })
      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })
    end,
  },

  -- ── Conform: formatting ─────────────────────────────────────────────────
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    cmd   = "ConformInfo",
    keys  = {
      { "<leader>cf", function() require("conform").format({ async = true }) end, desc = "Format buffer" },
    },
    opts = {
      formatters_by_ft = {
        lua        = { "stylua" },
        python     = { "ruff_format" },
        javascript = { "prettierd", "prettier", stop_after_first = true },
        typescript = { "prettierd", "prettier", stop_after_first = true },
        json       = { "prettierd", "prettier", stop_after_first = true },
        yaml       = { "prettierd", "prettier", stop_after_first = true },
        html       = { "prettierd", "prettier", stop_after_first = true },
        css        = { "prettierd", "prettier", stop_after_first = true },
        sh         = { "shfmt" },
        bash       = { "shfmt" },
        go         = { "gofmt" },
        rust       = { "rustfmt" },
        c          = { "clang-format" },
        cpp        = { "clang-format" },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
}
