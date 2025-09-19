-- Completion configuration - Tab to accept
return {
	{
		"hrsh7th/nvim-cmp",
		keys = {
			{
				"<tab>",
				function()
					return vim.snippet.active({ direction = 1 }) and "<cmd>lua vim.snippet.jump(1)<cr>" or "<tab>"
				end,
				expr = true,
				silent = true,
				mode = "i",
			},
			{
				"<tab>",
				function()
					return vim.snippet.active({ direction = 1 }) and "<cmd>lua vim.snippet.jump(1)<cr>" or "<tab>"
				end,
				expr = true,
				silent = true,
				mode = "s",
			},
		},
		opts = function(_, opts)
			local cmp = require("cmp")

			opts.mapping = vim.tbl_extend("force", opts.mapping or {}, {
				-- Simple Tab to accept
				["<Tab>"] = cmp.mapping.confirm({ select = true }),

				-- Enter does nothing with completion
				["<CR>"] = cmp.mapping(function(fallback)
					fallback()
				end),
			})

			return opts
		end,
	},
}
