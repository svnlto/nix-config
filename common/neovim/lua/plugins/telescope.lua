-- Telescope Configuration
return {
	{
		"nvim-telescope/telescope.nvim",
		opts = {
			defaults = {
				prompt_prefix = " ",
				selection_caret = " ",
				path_display = { "truncate" },
				sorting_strategy = "ascending",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.55,
						results_width = 0.8,
					},
					vertical = {
						mirror = false,
					},
					width = 0.87,
					height = 0.80,
					preview_cutoff = 120,
				},
			},
			pickers = {
				find_files = {
					find_command = { "rg", "--files", "--sortr=modified", "--hidden", "--glob", "!.git" },
				},
			},
		},
	},
}
