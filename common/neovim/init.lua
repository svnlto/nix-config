-- init.lua - Zed-like Neovim Configuration
-- Place this in ~/.config/nvim/init.lua

-- Set leader key early
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings that match Zed's feel
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.termguicolors = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.wrap = false
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8
vim.opt.updatetime = 250
vim.opt.timeoutlen = 300
vim.opt.completeopt = "menu,menuone,noselect"
vim.opt.pumheight = 10
vim.opt.conceallevel = 2
vim.opt.undofile = true
vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false

-- Print margin indicator at 80 characters (matching Zed config)
vim.opt.colorcolumn = "80"

-- Add gap to the right of line numbers using modern statuscolumn
vim.opt.signcolumn = "yes"
vim.opt.statuscolumn = "%s%=%{v:relnum?v:relnum:v:lnum}   "  -- Three spaces after numbers

-- Terminal integration and sizing
vim.opt.ttyfast = true
vim.opt.lazyredraw = false

-- Remove intro message
vim.opt.shortmess:append("I")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Plugin specifications
local plugins = {
  -- Theme (similar to Zed's clean aesthetic)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha", -- matching Zed config
        transparent_background = false,
        integrations = {
          cmp = true,
          gitsigns = true,
          telescope = true,
          treesitter = true,
          mason = true,
          which_key = true,
        },
      })
      vim.cmd.colorscheme("catppuccin")
    end,
  },

  -- Fuzzy finder (like Zed's command palette)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    config = function()
      require("telescope").setup({
        defaults = {
          prompt_prefix = " ",
          selection_caret = " ",
          path_display = { "truncate" },
          sorting_strategy = "ascending",
          layout_config = {
            horizontal = {
              prompt_position = "top",
              preview_width = 0.55,
              results_width = 0.8,
            },
            vertical = {
              mirror = false,
            },
            width = 0.87,
            height = 0.80,
            preview_cutoff = 120,
          },
        },
      })
    end,
  },

  -- File explorer (nvim-tree)
  {
    "nvim-tree/nvim-tree.lua",
    dependencies = {
      "nvim-tree/nvim-web-devicons", -- File icons
    },
    config = function()
      -- nvim-tree setup - minimal like Zed
      require("nvim-tree").setup({
        -- Disable netrw completely
        disable_netrw = true,
        hijack_netrw = true,

        -- Window/UI settings
        view = {
          width = 40,
          side = "left",
          number = false,
          relativenumber = false,
          signcolumn = "no",
        },

        -- Renderer settings for minimal UI
        renderer = {
          add_trailing = false,
          group_empty = true,
          highlight_git = true,
          full_name = false,
          highlight_opened_files = "none",
          root_folder_label = ":~:s?$?/..",
          indent_width = 2,
          indent_markers = {
            enable = false,
          },
          icons = {
            webdev_colors = false,
            git_placement = "after",
            modified_placement = "after",
            padding = " ",
            symlink_arrow = " → ",
            show = {
              file = false,  -- No file icons for minimal look
              folder = false, -- No folder icons
              folder_arrow = false, -- No arrows
              git = true,    -- Show git status
              modified = true,
            },
            glyphs = {
              default = "",
              symlink = "",
              bookmark = "",
              modified = "●",
              folder = {
                arrow_closed = "",
                arrow_open = "",
                default = "",
                open = "",
                empty = "",
                empty_open = "",
                symlink = "",
                symlink_open = "",
              },
              git = {
                unstaged = "!",
                staged = "+",
                unmerged = "",
                renamed = "»",
                untracked = "?",
                deleted = "✗",
                ignored = "◌",
              },
            },
          },
        },

        -- Hide dotfiles but show git files
        filters = {
          dotfiles = false,
          git_clean = false,
          no_buffer = false,
          custom = { ".git", ".DS_Store", "node_modules", "__pycache__", ".turbo", ".env" },
          exclude = {},
        },

        -- Git integration
        git = {
          enable = true,
          ignore = true,
          show_on_dirs = true,
          show_on_open_dirs = true,
          timeout = 400,
        },

        -- Actions
        actions = {
          use_system_clipboard = true,
          change_dir = {
            enable = true,
            global = false,
            restrict_above_cwd = false,
          },
          open_file = {
            quit_on_open = false,
            resize_window = true,
            window_picker = {
              enable = true,
              picker = "default",
              chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
              exclude = {
                filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
                buftype = { "nofile", "terminal", "help" },
              },
            },
          },
          remove_file = {
            close_window = true,
          },
        },

        -- Log settings (disable for performance)
        log = {
          enable = false,
        },

        -- Key mappings for nvim-tree
        on_attach = function(bufnr)
          local api = require("nvim-tree.api")

          local function opts(desc)
            return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
          end

          -- Default mappings
          api.config.mappings.default_on_attach(bufnr)

          -- Custom mappings for splits
          vim.keymap.set("n", "s", api.node.open.vertical, opts("Open: Vertical Split"))
          vim.keymap.set("n", "v", api.node.open.horizontal, opts("Open: Horizontal Split"))
        end,
      })


      -- Auto-open nvim-tree on startup if no file specified
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          if vim.fn.argc() == 0 then
            require("nvim-tree.api").tree.open()
          elseif vim.fn.argc() == 1 and vim.fn.isdirectory(vim.fn.argv(0)) == 1 then
            require("nvim-tree.api").tree.open({ path = vim.fn.argv(0) })
          end
        end,
      })

      -- Prevent nvim-tree from being the last window
      vim.api.nvim_create_autocmd("BufEnter", {
        nested = true,
        callback = function()
          if #vim.api.nvim_list_wins() == 1 and require("nvim-tree.utils").is_nvim_tree_buf() then
            vim.cmd("quit")
          end
        end,
      })

      -- Sync nvim-tree when opening files via telescope
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          if vim.bo.buftype == "" and vim.bo.filetype ~= "NvimTree" then
            local api = require("nvim-tree.api")
            if api.tree.is_visible() then
              api.tree.find_file({ buf = vim.api.nvim_get_current_buf() })
            end
          end
        end,
      })

      -- Custom highlights for minimal Catppuccin Mocha theme
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = function()
          vim.cmd([[
            highlight NvimTreeNormal guifg=#7f849c guibg=NONE
            highlight NvimTreeFolderName guifg=#6c7086 gui=NONE
            highlight NvimTreeFolderIcon guifg=#6c7086 gui=NONE
            highlight NvimTreeOpenedFolderName guifg=#6c7086 gui=NONE
            highlight NvimTreeEmptyFolderName guifg=#585b70 gui=NONE
            highlight NvimTreeIndentMarker guifg=#585b70 gui=NONE
            highlight NvimTreeWinSeparator guifg=#313244 guibg=NONE
            highlight NvimTreeRootFolder guifg=#6c7086 gui=NONE
            highlight NvimTreeSymlink guifg=#89dceb gui=NONE
            highlight NvimTreeFolderArrowClosed guifg=#585b70 gui=NONE
            highlight NvimTreeFolderArrowOpen guifg=#585b70 gui=NONE

            " Git status colors
            highlight NvimTreeGitDirty guifg=#a6adc8 gui=NONE
            highlight NvimTreeGitStaged guifg=#94e2d5 gui=NONE
            highlight NvimTreeGitMerge guifg=#f9e2af gui=NONE
            highlight NvimTreeGitRenamed guifg=#89dceb gui=NONE
            highlight NvimTreeGitNew guifg=#fab387 gui=NONE
            highlight NvimTreeGitDeleted guifg=#f5c2e7 gui=NONE
            highlight NvimTreeGitIgnored guifg=#585b70 gui=NONE
          ]])
        end,
      })
    end,
  },

  -- LSP Configuration
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "j-hui/fidget.nvim",
    },
    config = function()
      require("mason").setup()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls", -- TypeScript/JavaScript (updated name)
          "terraformls", -- Terraform
          "lua_ls", -- Keep Lua for Neovim config editing
          "biome", -- Biome LSP for linting and formatting
        },
        automatic_enable = false, -- Disable automatic enabling to prevent errors
      })

      require("fidget").setup()

      local lspconfig = require("lspconfig")
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      -- TypeScript/JavaScript
      lspconfig.ts_ls.setup({
        capabilities = capabilities,
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
      })

      -- Terraform
      lspconfig.terraformls.setup({
        capabilities = capabilities,
        filetypes = { "terraform", "tf" },
      })

      -- Lua (for Neovim config)
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
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
      })

      -- Biome LSP (official integration)
      lspconfig.biome.setup({
        capabilities = capabilities,
        filetypes = { "javascript", "javascriptreact", "json", "jsonc", "typescript", "typescriptreact" },
        root_dir = lspconfig.util.root_pattern("biome.json", ".git"),
      })

      -- LSP keymaps
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("UserLspConfig", {}),
        callback = function(ev)
          local opts = { buffer = ev.buf }
          vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
          vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
          vim.keymap.set("n", "K", vim.lsp.buf.hover, opts)
          vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)
          vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")

      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<C-b>"] = cmp.mapping.scroll_docs(-4),
          ["<C-f>"] = cmp.mapping.scroll_docs(4),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
        }, {
          { name = "buffer" },
          { name = "path" },
        }),
      })
    end,
  },

  -- Treesitter for syntax highlighting
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "lua", "vim", "vimdoc", "query",
          "javascript", "typescript", "tsx", "json",
          "hcl", "terraform", -- Terraform files
          "yaml", "markdown",
        },
        sync_install = false,
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Status line (clean like Zed)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          icons_enabled = true,
          theme = "auto",
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff", "diagnostics" },
          lualine_c = { "filename" },
          lualine_x = { "encoding", "fileformat", "filetype" },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
      })
    end,
  },

  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    config = function()
      require("nvim-autopairs").setup()
    end,
  },

  -- Comment toggling
  {
    "numToStr/Comment.nvim",
    config = function()
      require("Comment").setup()
    end,
  },

  -- Which-key for keybinding hints
  {
    "folke/which-key.nvim",
    config = function()
      require("which-key").setup()
    end,
  },

  -- Better buffer management
  {
    "akinsho/bufferline.nvim",
    dependencies = "nvim-tree/nvim-web-devicons",
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          separator_style = "thin",
          always_show_bufferline = false,
          show_buffer_close_icons = false,
          show_close_icon = false,
          color_icons = true,
        },
      })
    end,
  },

  -- Indent guides
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        indent = {
          char = "│",
          highlight = "IblIndent",
        },
        scope = {
          enabled = false, -- Disable scope highlighting to reduce visual noise
        },
      })

      -- Set subtle colors for indent guides (matching Catppuccin Mocha theme)
      vim.api.nvim_set_hl(0, "IblIndent", { fg = "#313244" }) -- Very subtle gray
    end,
  },

  -- Markdown preview with Mermaid support
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    init = function()
      vim.g.mkdp_filetypes = { "markdown" }
    end,
    ft = { "markdown" },
    config = function()
      vim.keymap.set("n", "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", { desc = "Markdown Preview Toggle" })

      -- Mermaid and diagram support
      vim.g.mkdp_preview_options = {
        mkit = {},
        katex = {},
        uml = {},
        maid = {},
        disable_sync_scroll = 0,
        sync_scroll_type = 'middle',
        hide_yaml_meta = 1,
        sequence_diagrams = {},
        flowchart_diagrams = {},
        content_editable = false,
        disable_filename = 0,
        toc = {}
      }
    end,
  },

}

-- Setup lazy.nvim
require("lazy").setup(plugins, {
  ui = {
    border = "rounded",
  },
})

-- Key mappings (Zed-inspired)
local keymap = vim.keymap.set

-- General
keymap("n", "<leader><leader>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
keymap("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Search in files" })
keymap("n", "<leader>b", "<cmd>Telescope buffers<cr>", { desc = "Switch buffer" })
keymap("n", "<leader>:", "<cmd>Telescope commands<cr>", { desc = "Commands" })

-- File explorer
keymap("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file explorer" })

-- Buffer management
keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
keymap("n", "<leader>x", "<cmd>bd<cr>", { desc = "Close buffer" })

-- Navigation
keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

-- Better up/down
keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Clear search with <esc>
keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Better indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Move Lines
keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Auto commands for better UX
local function augroup(name)
  return vim.api.nvim_create_augroup("zed_" .. name, { clear = true })
end

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("highlight_yank"),
  callback = function()
    vim.highlight.on_yank()
  end,
})

-- Close some filetypes with <q>
vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = {
    "PlenaryTestPopup",
    "help",
    "lspinfo",
    "man",
    "notify",
    "qf",
    "spectre_panel",
    "startuptime",
    "tsplayground",
    "neotest-output",
    "checkhealth",
    "neotest-summary",
    "neotest-output-panel",
  },
  callback = function(event)
    vim.bo[event.buf].buflisted = false
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
  end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
vim.api.nvim_create_autocmd({ "BufWritePre" }, {
  group = augroup("auto_create_dir"),
  callback = function(event)
    if event.match:match("^%w%w+://") then
      return
    end
    local file = vim.loop.fs_realpath(event.match) or event.match
    vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
  end,
})

-- Fix terminal size detection
vim.api.nvim_create_autocmd({ "VimEnter", "VimResized" }, {
  group = augroup("terminal_resize"),
  callback = function()
    vim.cmd("redraw!")
  end,
})
