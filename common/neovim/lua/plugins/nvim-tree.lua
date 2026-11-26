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
			-- Define all nvim-tree signs BEFORE setup to prevent sign_place errors
			local signs = {
				NvimTreeBookmarkIcon = { text = "", texthl = "NvimTreeSymlink" },
				NvimTreeGitDirty = { text = "!", texthl = "NvimTreeGitDirty" },
				NvimTreeGitStaged = { text = "+", texthl = "NvimTreeGitStaged" },
				NvimTreeGitMerge = { text = "", texthl = "NvimTreeGitMerge" },
				NvimTreeGitRenamed = { text = "»", texthl = "NvimTreeGitRenamed" },
				NvimTreeGitNew = { text = "?", texthl = "NvimTreeGitNew" },
				NvimTreeGitDeleted = { text = "✗", texthl = "NvimTreeGitDeleted" },
				NvimTreeGitIgnored = { text = "◌", texthl = "NvimTreeGitIgnored" },
			}

			-- Define signs immediately, before nvim-tree setup
			for name, opts in pairs(signs) do
				pcall(vim.fn.sign_define, name, opts)
			end

			require("nvim-tree").setup({
				-- Disable netrw completely
				disable_netrw = true,
				hijack_netrw = true,

				-- Window/UI settings
				view = {
					width = 35,
					side = "left",
					number = false,
					relativenumber = false,
					signcolumn = "no",
				},

				-- Renderer settings for minimal UI
				renderer = {
					add_trailing = false,
					group_empty = false, -- Show all directories, don't group empty ones
					highlight_git = "name",
					full_name = false,
					highlight_opened_files = "none",
					root_folder_label = ":~:s?$?/..",
					indent_width = 2,
					indent_markers = {
						enable = false,
					},
					icons = {
						git_placement = "after",
						modified_placement = "after",
						padding = { icon = " " },
						web_devicons = { file = { color = false } },
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
					git_ignored = false, -- Show git-ignored files (was git.ignore)
					git_clean = false,
					no_buffer = false, -- Show all files regardless of buffer status
					custom = { ".DS_Store" }, -- Only hide system files
					exclude = {}, -- Don't exclude any patterns
				},

				-- Git integration
				git = {
					enable = true,
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
					update_root = { enable = false },
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
						return {
							desc = "nvim-tree: " .. desc,
							buffer = bufnr,
							noremap = true,
							silent = true,
							nowait = true,
						}
					end

					-- Default mappings (but filter out bookmark mappings that cause sign errors)
					api.map.on_attach.default(bufnr)

					-- Remove any bookmark-related mappings that might trigger sign errors
					pcall(vim.keymap.del, "n", "m", { buffer = bufnr })
					pcall(vim.keymap.del, "n", "bd", { buffer = bufnr })
					pcall(vim.keymap.del, "n", "bt", { buffer = bufnr })

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
					elseif vim.fn.argc() == 1 then
						local arg = vim.fn.argv(0) --[[@as string]]
						if vim.fn.isdirectory(arg) == 1 then
							require("nvim-tree.api").tree.open({ path = arg })
						end
					end
				end,
			})

			-- Prevent nvim-tree from being the last window (use QuitPre, not BufEnter)
			vim.api.nvim_create_autocmd("QuitPre", {
				callback = function()
					local tree_wins = {}
					local floating_wins = {}
					local wins = vim.api.nvim_list_wins()
					for _, w in ipairs(wins) do
						local bufname = vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(w))
						if bufname:match("NvimTree_") ~= nil then
							table.insert(tree_wins, w)
						end
						if vim.api.nvim_win_get_config(w).relative ~= "" then
							table.insert(floating_wins, w)
						end
					end
					if 1 == #wins - #floating_wins - #tree_wins then
						for _, w in ipairs(tree_wins) do
							vim.api.nvim_win_close(w, true)
						end
					end
				end,
			})

			-- Sync nvim-tree when opening files
			vim.api.nvim_create_autocmd("BufEnter", {
				callback = function()
					if vim.bo.buftype == "" and vim.bo.filetype ~= "NvimTree" then
						local ok, api = pcall(require, "nvim-tree.api")
						if ok and api.tree.is_visible() then
							api.tree.find_file({ buf = vim.api.nvim_get_current_buf() })
						end
					end
				end,
			})

			-- Custom highlights for minimal Catppuccin theme (follows the active flavour)
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = function()
					local ok, palettes = pcall(require, "catppuccin.palettes")
					if not ok then
						return
					end
					local c = palettes.get_palette()
					local highlights = {
						NvimTreeNormal = { fg = c.overlay1, bg = "NONE" },
						NvimTreeFolderName = { fg = c.overlay0 },
						NvimTreeFolderIcon = { fg = c.overlay0 },
						NvimTreeOpenedFolderName = { fg = c.overlay0 },
						NvimTreeEmptyFolderName = { fg = c.surface2 },
						NvimTreeIndentMarker = { fg = c.surface2 },
						NvimTreeWinSeparator = { fg = c.surface0, bg = "NONE" },
						NvimTreeRootFolder = { fg = c.overlay0 },
						NvimTreeSymlink = { fg = c.sky },
						NvimTreeFolderArrowClosed = { fg = c.surface2 },
						NvimTreeFolderArrowOpen = { fg = c.surface2 },
						NvimTreeGitDirty = { fg = c.subtext0 },
						NvimTreeGitStaged = { fg = c.teal },
						NvimTreeGitMerge = { fg = c.yellow },
						NvimTreeGitRenamed = { fg = c.sky },
						NvimTreeGitNew = { fg = c.peach },
						NvimTreeGitDeleted = { fg = c.pink },
						NvimTreeGitIgnored = { fg = c.surface2 },
					}
					for group, spec in pairs(highlights) do
						vim.api.nvim_set_hl(0, group, spec)
					end
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
		end,
	},
}
