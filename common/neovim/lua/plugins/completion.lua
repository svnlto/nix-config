-- Completion configuration - Tab to accept (blink.cmp)
return {
	{
		"saghen/blink.cmp",
		opts = {
			keymap = {
				-- Tab to accept completion
				["<Tab>"] = { "accept", "fallback" },
				-- Enter does nothing with completion (normal newline)
				["<CR>"] = {},
			},
		},
	},
}
