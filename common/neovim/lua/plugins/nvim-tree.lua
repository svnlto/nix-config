-- File Explorer - nvim-tree with proper Catppuccin integration
return {
  -- Disable LazyVim's default neo-tree
  {
    "nvim-neo-tree/neo-tree.nvim",
    enabled = false,
  },

  -- Configure nvim-tree with Catppuccin integration
  {
    "nvim-tree/nvim-tree.lua",
    enabled = true,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
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
          group_empty = false, -- Show all directories, don't group empty ones
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
              file = false, -- No file icons for minimal look
              folder = false, -- No folder icons
              folder_arrow = false, -- No arrows
              git = true, -- Show git status
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

        -- Show all files including dotfiles
        filters = {
          dotfiles = false, -- Show dotfiles (.env, .gitignore, etc.)
          git_clean = false, -- Show git-ignored files
          no_buffer = false, -- Show all files regardless of buffer status
          custom = { ".DS_Store" }, -- Only hide system files
          exclude = {}, -- Don't exclude any patterns
        },

        -- Git integration
        git = {
          enable = true,
          ignore = false, -- Show git-ignored files (like .env, build files, etc.)
          show_on_dirs = true,
          show_on_open_dirs = true,
          timeout = 400,
        },

        -- Disable features that can cause sign conflicts
        diagnostics = {
          enable = false, -- Disable to prevent sign conflicts
        },

        -- Enable file sync to keep tree updated with current buffer
        update_focused_file = {
          enable = true,
          update_root = false, -- Don't change root when following files
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

      -- Auto-refresh nvim-tree when files change
      vim.api.nvim_create_autocmd({ "BufWritePost", "FileChangedShellPost" }, {
        callback = function()
          local api = require("nvim-tree.api")
          if api.tree.is_visible() then
            api.tree.reload()
          end
        end,
      })

      -- Fix nvim-tree sign issues by ensuring all signs are properly defined
      vim.api.nvim_create_autocmd("VimEnter", {
        callback = function()
          -- Clear any problematic signs that might cause errors
          pcall(vim.fn.sign_undefine, "NvimTreeBookmarkIcon")
          -- Ensure the git runner doesn't interfere with sign placement
          vim.schedule(function()
            if vim.fn.exists("*nvim_tree#git#runner#new") == 1 then
              -- Restart git runner with better error handling
              pcall(vim.cmd, "NvimTreeRefresh")
            end
          end)
        end,
      })
    end,
  },
}
