return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false,
		opts = {
			flavour = "mocha",
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
			require("catppuccin").setup(opts)
			vim.cmd.colorscheme("catppuccin")

			-- Set pink cursor color after colorscheme loads
			vim.api.nvim_set_hl(0, "Cursor", { bg = "#FF24C0", fg = "#1e1e2e" })
			vim.api.nvim_set_hl(0, "lCursor", { bg = "#FF24C0", fg = "#1e1e2e" })

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
