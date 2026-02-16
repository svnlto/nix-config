-- Fuzzy finder configuration (fzf-lua, LazyVim v14+ default)
return {
	{
		"ibhagwan/fzf-lua",
		opts = {
			defaults = {
				formatter = "path.filename_first",
			},
			files = {
				cmd = "rg --files --sortr=modified --hidden --glob '!.git'",
			},
			winopts = {
				width = 0.87,
				height = 0.80,
				preview = {
					horizontal = "right:55%",
				},
			},
		},
	},
}
