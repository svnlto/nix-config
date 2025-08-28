-- LSP Configuration
return {
  -- Configure nvim-lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- Configure LSP servers
      servers = {
        -- TypeScript/JavaScript (updated name)
        ts_ls = {
          settings = {
            typescript = {
              inlayHints = {
                includeInlayParameterNameHints = "literal",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = false,
                includeInlayVariableTypeHints = false,
                includeInlayPropertyDeclarationTypeHints = false,
                includeInlayFunctionLikeReturnTypeHints = false,
                includeInlayEnumMemberValueHints = false,
              },
            },
            javascript = {
              inlayHints = {
                includeInlayParameterNameHints = "all",
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
              },
            },
          },
        },

        -- Terraform
        terraformls = {
          filetypes = { "terraform", "tf" },
        },

        -- Lua (for Neovim config)
        lua_ls = {
          settings = {
            Lua = {
              runtime = { version = "LuaJIT" },
              diagnostics = { globals = { "vim" } },
              workspace = {
                library = vim.api.nvim_get_runtime_file("", true),
                checkThirdParty = false,
              },
              telemetry = { enable = false },
            },
          },
        },

        -- Biome LSP (official integration)
        biome = {
          filetypes = { "javascript", "javascriptreact", "json", "jsonc", "typescript", "typescriptreact" },
          root_dir = function(fname)
            local lspconfig = require("lspconfig")
            return lspconfig.util.root_pattern("biome.json", ".git")(fname)
          end,
        },
      },
    },
  },

  -- Mason configuration
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "typescript-language-server",
        "terraform-ls",
        "lua-language-server",
        "biome",
      },
    },
  },
}
