-- jj support for colocated repos: jjui in a terminal float, plus a lualine
-- component showing the nearest bookmark. LazyVim's `branch` component reads
-- gitsigns' head, which under jj is a bare commit hash (jj keeps git HEAD
-- detached), so it is hidden while inside a jj repo.

local labels = {}

-- Nearest bookmark for the working-copy commit, else its change ID. jj lists
-- `@` first, so line 1 carries the change ID and the first non-empty bookmark
-- field belongs to the closest ancestor bookmark. --ignore-working-copy keeps
-- this read-only; without it every redraw would snapshot the working copy.
local function refresh(root)
	vim.system({
		"jj",
		"log",
		"--no-graph",
		"--ignore-working-copy",
		"-r",
		"@ | heads(::@ & bookmarks())",
		"-T",
		'bookmarks ++ "|" ++ change_id.short(8) ++ "\n"',
	}, { cwd = root, text = true }, function(res)
		local label = ""
		if res.code == 0 then
			for line in vim.gsplit(res.stdout or "", "\n", { trimempty = true }) do
				local bookmark, change = line:match("^([^|]*)|(.*)$")
				if bookmark and bookmark ~= "" then
					label = bookmark
					break
				end
				if label == "" and change then
					label = change
				end
			end
		end
		labels[root] = label
		vim.schedule(function()
			vim.cmd.redrawstatus()
		end)
	end)
end

local function detect(buf)
	if not vim.api.nvim_buf_is_valid(buf) then
		return
	end
	local name = vim.api.nvim_buf_get_name(buf)
	local dir = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
	local found = vim.fs.find(".jj", { upward = true, path = dir, type = "directory" })[1]
	local root = found and vim.fs.dirname(found) or nil
	vim.b[buf].jj_root = root
	if root and labels[root] == nil then
		refresh(root)
	end
end

local function bookmark()
	local root = vim.b.jj_root
	return root and labels[root] or ""
end

return {
	{
		"folke/snacks.nvim",
		keys = {
			{
				"<leader>gj",
				function()
					Snacks.terminal({ "jjui" }, { cwd = LazyVim.root.get() })
				end,
				desc = "jjui (Root Dir)",
			},
			{
				"<leader>gJ",
				function()
					Snacks.terminal({ "jjui" })
				end,
				desc = "jjui (cwd)",
			},
		},
	},

	{
		"nvim-lualine/lualine.nvim",
		init = function()
			vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "DirChanged" }, {
				callback = function(ev)
					detect(ev.buf)
				end,
			})

			-- jj rewrites commits outside nvim's view, so re-read after jjui
			-- exits or focus returns.
			vim.api.nvim_create_autocmd({ "FocusGained", "TermClose" }, {
				callback = function()
					for root in pairs(labels) do
						refresh(root)
					end
				end,
			})
		end,
		opts = function(_, opts)
			opts.sections = opts.sections or {}
			local section = opts.sections.lualine_b or {}

			for i, component in ipairs(section) do
				if component == "branch" then
					section[i] = {
						"branch",
						cond = function()
							return vim.b.jj_root == nil
						end,
					}
				end
			end

			table.insert(section, 1, {
				bookmark,
				icon = "",
				cond = function()
					return vim.b.jj_root ~= nil
				end,
			})

			opts.sections.lualine_b = section
			return opts
		end,
	},
}
