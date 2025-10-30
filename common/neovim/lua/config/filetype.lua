-- Detect Jinja2 syntax in YAML files and set compound filetype
vim.filetype.add({
	pattern = {
		["%.yaml"] = {
			function(path, bufnr)
				-- Read first 50 lines to detect Jinja syntax
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
				local content = table.concat(lines, "\n")

				-- Check for Jinja2 patterns: {%, {{, {#
				if content:match("{%%") or content:match("{{") or content:match("{#") then
					return "yaml.jinja"
				end

				return "yaml"
			end,
			priority = 10,
		},
		["%.yml"] = {
			function(path, bufnr)
				-- Read first 50 lines to detect Jinja syntax
				local lines = vim.api.nvim_buf_get_lines(bufnr, 0, 50, false)
				local content = table.concat(lines, "\n")

				-- Check for Jinja2 patterns: {%, {{, {#
				if content:match("{%%") or content:match("{{") or content:match("{#") then
					return "yaml.jinja"
				end

				return "yaml"
			end,
			priority = 10,
		},
	},
	extension = {
		-- Explicit extensions for Jinja YAML files
		["yaml.j2"] = "yaml.jinja",
		["yml.j2"] = "yaml.jinja",
		["yaml.jinja"] = "yaml.jinja",
		["yml.jinja"] = "yaml.jinja",
		["yaml.jinja2"] = "yaml.jinja",
		["yml.jinja2"] = "yaml.jinja",
	},
})
