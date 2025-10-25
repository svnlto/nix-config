return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		opts = {
			flavour = "mocha",
			transparent_background = true,
			term_colors = false, -- Disable terminal color overrides to preserve terminal cursor color
			integrations = {
				bufferline = false,
				cmp = true,
				gitsigns = true,
				nvimtree = true,
				treesitter = true,
				telescope = true,
				which_key = true,
				native_lsp = {
					enabled = true,
				},
			},
		},
		config = function(_, opts)
			-- Extend opts to customize cursor colors
			opts.custom_highlights = function(colors)
				return {
					Cursor = { bg = "#FF24C0", fg = colors.base },
					lCursor = { bg = "#FF24C0", fg = colors.base },
					TermCursor = { bg = "#FF24C0", fg = colors.base },
					TermCursorNC = { bg = "#FF24C0", fg = colors.base },
				}
			end

			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")

			vim.schedule(function()
				if pcall(require, "nvim-tree") then
					vim.cmd("doautocmd ColorScheme")
				end
			end)
		end,
	},

	{
		"akinsho/bufferline.nvim",
		enabled = false,
	},

	{
		"LazyVim/LazyVim",
		opts = {
			colorscheme = "catppuccin",
		},
	},
}
