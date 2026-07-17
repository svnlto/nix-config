-- Treesitter Configuration
return {
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			-- Extend ensure_installed list (LazyVim uses opts_extend for this)
			vim.list_extend(opts.ensure_installed, {
				"hcl",
				"jinja",
				"terraform",
			})

			-- Register language mappings for compound filetypes
			-- register(lang, filetype): map the jinja parser onto jinja filetypes
			vim.treesitter.language.register("yaml", "yaml.jinja")
			vim.treesitter.language.register("jinja", "jinja")

			return opts
		end,
	},
}
