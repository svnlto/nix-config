-- Treesitter Configuration
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- Extend ensure_installed list (LazyVim uses opts_extend for this)
			vim.list_extend(opts.ensure_installed, {
				"jinja2",
			})

			-- Register language mappings for compound filetypes
			vim.treesitter.language.register("yaml", "yaml.jinja")
			vim.treesitter.language.register("jinja2", "jinja")

			return opts
		end,
	},
}
