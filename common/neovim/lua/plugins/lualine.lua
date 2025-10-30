-- Lualine statusline configuration
return {
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			-- Ensure filetype is shown in lualine
			opts.sections = opts.sections or {}
			opts.sections.lualine_x = opts.sections.lualine_x or {}

			-- Add filetype to the right side if not already present
			local has_filetype = false
			for _, component in ipairs(opts.sections.lualine_x) do
				if component == "filetype" or (type(component) == "table" and component[1] == "filetype") then
					has_filetype = true
					break
				end
			end

			if not has_filetype then
				table.insert(opts.sections.lualine_x, "filetype")
			end

			return opts
		end,
	},
}
