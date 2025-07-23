-- init.lua - Zed-like Neovim Configuration
-- Place this in ~/.config/nvim/init.lua

-- Set leader key early
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Basic settings that match Zed's feel
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
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

  -- File explorer (NERDTree)
  {
    "preservim/nerdtree",
    dependencies = {
      "ryanoasis/vim-devicons",
    },
    config = function()
      -- NERDTree settings - clean and minimal
      vim.g.NERDTreeWinSize = 30
      vim.g.NERDTreeShowHidden = 0
      vim.g.NERDTreeMinimalUI = 1
      vim.g.NERDTreeDirArrows = 1
      vim.g.NERDTreeShowLineNumbers = 0
      vim.g.NERDTreeWinPos = "left"
      vim.g.NERDTreeIgnore = {'\\.git$', '\\.DS_Store$', 'node_modules', '__pycache__', '\\.turbo$', '\\.env$', '\\.env\\..*$'}
      vim.g.NERDTreeAutoDeleteBuffer = 1
      vim.g.NERDTreeQuitOnOpen = 0
      vim.g.NERDTreeShowBookmarks = 0
      vim.g.NERDTreeMinimalMenu = 1
      vim.g.NERDTreeCascadeSingleChildDir = 1
      vim.g.NERDTreeCascadeOpenSingleChildDir = 1

      -- Clean visual styling
      vim.g.NERDTreeMarkBookmarks = 0
      vim.g.NERDTreeHijackNetrw = 1
      vim.g.NERDTreeChDirMode = 2

      -- Disable git plugin and other decorators to avoid clutter
      vim.g.NERDTreeGitStatusEnable = 0
      vim.g.loaded_nerd_tree_git_status = 1

      -- Custom NERDTree highlights for cleaner look with Catppuccin Mocha colors
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          vim.cmd([[
            highlight NERDTreeDir ctermfg=blue guifg=#89b4fa
            highlight NERDTreeDirSlash ctermfg=blue guifg=#89b4fa
            highlight NERDTreeFile ctermfg=white guifg=#cdd6f4
            highlight NERDTreeExecFile ctermfg=green guifg=#a6e3a1
            highlight NERDTreeOpenable ctermfg=blue guifg=#89b4fa
            highlight NERDTreeClosable ctermfg=blue guifg=#89b4fa
          ]])
        end,
      })

      -- Start NERDTree when Vim is started without file arguments
      vim.api.nvim_create_autocmd("StdinReadPre", {
        pattern = "*",
        callback = function()
          vim.g.std_in = 1
        end,
      })

      vim.api.nvim_create_autocmd("VimEnter", {
        pattern = "*",
        callback = function()
          if vim.fn.argc() == 0 and not vim.g.std_in then
            vim.cmd("NERDTree")
          end
        end,
      })

      -- Auto-close NERDTree if it's the only window left
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          if vim.fn.winnr("$") == 1 and vim.fn.exists("b:NERDTree") == 1 and vim.b.NERDTree.isTabTree() then
            vim.cmd("q")
          end
        end,
      })

      -- If more than one window and previous buffer was nerdtree, go back to it
      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        callback = function()
          if vim.bo.buftype == "" and vim.fn.winnr("$") > 1 then
            -- Focus the previous window if we opened a file from NERDTree
            local prev_winnr = vim.fn.winnr("#")
            if prev_winnr ~= 0 and vim.fn.getbufvar(vim.fn.winbufnr(prev_winnr), "&filetype") == "nerdtree" then
              return
            end
          end
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
      require("ibl").setup()
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
keymap("n", "<leader>e", "<cmd>NERDTreeToggle<cr>", { desc = "Toggle file explorer" })

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
