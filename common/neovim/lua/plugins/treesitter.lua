-- Treesitter Configuration
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				"lua",
				"vim",
				"vimdoc",
				"query",
				"javascript",
				"typescript",
				"tsx",
				"json",
				"go",
				"gomod",
				"gowork",
				"terraform",
				"yaml",
				"markdown",
				"dockerfile",
				"jinja2",
			},
			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
			},
			indent = {
				enable = true,
			},
			incremental_selection = {
				enable = true,
			},
		},
		config = function(_, opts)
			require("nvim-treesitter.configs").setup(opts)

			-- Register jinja2 parser for compound filetypes
			vim.treesitter.language.register("jinja2", "jinja")
		end,
	},
}
