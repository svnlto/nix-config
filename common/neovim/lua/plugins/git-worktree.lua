-- Switch nvim's global cwd to a git worktree of the current repo, and
-- re-point open file buffers to the same paths in the new worktree.
-- Reuses fzf-lua (already the picker); no new plugin dependency.

-- Directory to resolve the repo from: the current buffer's dir, else cwd.
local function repo_dir()
	local buf = vim.api.nvim_buf_get_name(0)
	if buf ~= "" then
		return vim.fn.fnamemodify(buf, ":h")
	end
	return vim.loop.cwd()
end

-- Absolute root of the worktree containing `dir`, or nil if not in a repo.
local function toplevel(dir)
	local out = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error ~= 0 then
		return nil
	end
	return out[1]
end

-- Parse `git worktree list --porcelain` into an ordered list of entries.
-- Each entry: { path, is_main, branch?, detached? }. `bare` and `prunable`
-- (stale/missing) records are dropped — nothing valid to cd into. Main
-- worktree is git's first record.
local function worktrees(dir)
	local lines = vim.fn.systemlist({ "git", "-C", dir, "worktree", "list", "--porcelain" })
	if vim.v.shell_error ~= 0 then
		return nil, "not a git repository"
	end

	local entries, cur, first = {}, nil, true
	local function flush()
		if cur and not cur.bare and not cur.prunable then
			entries[#entries + 1] = cur
		end
		cur = nil
	end
	for _, line in ipairs(lines) do
		if line:match("^worktree ") then
			flush()
			cur = { path = line:sub(10), is_main = first }
			first = false
		elseif cur then
			if line:match("^branch ") then
				cur.branch = line:gsub("^branch refs/heads/", "")
			elseif line == "detached" then
				cur.detached = true
			elseif line == "bare" then
				cur.bare = true
			elseif line:match("^prunable") then
				cur.prunable = true
			end
		end
	end
	flush()
	return entries
end

-- Re-point loaded, unmodified file buffers under old_root to the same
-- relative path under new_root, when that file exists there. Windows
-- showing a buffer are switched in place; the stale buffer is wiped.
-- Returns the count of unsaved buffers left untouched.
local function follow_buffers(old_root, new_root)
	local prefix = old_root .. "/"
	local skipped = 0
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local name = vim.api.nvim_buf_get_name(buf)
		if
			name ~= ""
			and vim.api.nvim_buf_is_loaded(buf)
			and vim.bo[buf].buftype == ""
			and name:sub(1, #prefix) == prefix
		then
			local target = new_root .. "/" .. name:sub(#prefix + 1)
			if vim.loop.fs_stat(target) then
				if vim.bo[buf].modified then
					skipped = skipped + 1
				else
					local wins = vim.fn.win_findbuf(buf)
					if #wins > 0 then
						for _, win in ipairs(wins) do
							vim.api.nvim_win_call(win, function()
								vim.cmd.edit(vim.fn.fnameescape(target))
							end)
						end
					else
						vim.fn.bufadd(target)
					end
					pcall(vim.api.nvim_buf_delete, buf, {})
				end
			end
		end
	end
	return skipped
end

-- Open the picker and cd to the chosen worktree.
local function switch()
	local dir = repo_dir()
	local entries, err = worktrees(dir)
	if not entries then
		vim.notify(err, vim.log.levels.WARN)
		return
	end
	if #entries < 2 then
		vim.notify("only one worktree", vim.log.levels.INFO)
		return
	end

	-- Captured before cd so buffers can be re-pointed to the new worktree.
	local old_root = toplevel(dir)

	-- Line format: "<label>\t<~path>\t<raw path>". Only fields 1-2 are
	-- shown (--with-nth); the raw path is parsed back on select.
	local display = {}
	for _, e in ipairs(entries) do
		local name = e.branch or (e.detached and "(detached)") or "(bare)"
		if e.is_main then
			name = name .. " (main)"
		end
		display[#display + 1] = string.format("%s\t%s\t%s", name, vim.fn.fnamemodify(e.path, ":~"), e.path)
	end

	require("fzf-lua").fzf_exec(display, {
		prompt = "Worktree> ",
		formatter = false,
		fzf_opts = { ["--delimiter"] = "\t", ["--with-nth"] = "1,2" },
		actions = {
			default = function(selected)
				local sel = selected and selected[1]
				if not sel then
					return
				end
				local path = sel:match("[^\t]*$")
				if not path or path == "" then
					return
				end
				local ok, cderr = pcall(vim.cmd.cd, path)
				if not ok then
					vim.notify(tostring(cderr), vim.log.levels.ERROR)
					return
				end
				local skipped = 0
				if old_root and old_root ~= path then
					skipped = follow_buffers(old_root, path)
				end
				pcall(function()
					require("nvim-tree.api").tree.change_root(path)
				end)
				local msg = "→ " .. path
				if skipped > 0 then
					msg = msg .. string.format("  (%d unsaved left)", skipped)
				end
				vim.notify(msg)
			end,
		},
	})
end

return {
	"ibhagwan/fzf-lua",
	keys = {
		{ "<leader>gw", switch, desc = "Switch Worktree" },
	},
}
