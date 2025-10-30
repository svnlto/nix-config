local function augroup(name)
	return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end
vim.api.nvim_create_autocmd("TextYankPost", {
	group = augroup("highlight_yank"),
	callback = function()
		vim.highlight.on_yank()
	end,
})

vim.api.nvim_create_autocmd("FileType", {
	group = augroup("close_with_q"),
	pattern = {
		"PlenaryTestPopup",
		"help",
		"lspinfo",
		"man",
		"notify",
		"qf",
		"spectre_panel",
		"startuptime",
		"tsplayground",
		"neotest-output",
		"checkhealth",
		"neotest-summary",
		"neotest-output-panel",
	},
	callback = function(event)
		vim.bo[event.buf].buflisted = false
		vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
	end,
})

vim.api.nvim_create_autocmd({ "BufWritePre" }, {
	group = augroup("auto_create_dir"),
	callback = function(event)
		if event.match:match("^%w%w+://") then
			return
		end
		local file = vim.loop.fs_realpath(event.match) or event.match
		vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
	end,
})

vim.api.nvim_create_autocmd({ "VimEnter", "VimResized" }, {
	group = augroup("terminal_resize"),
	callback = function()
		vim.cmd("redraw!")
	end,
})

-- Disable spell checking for all file types (overrides LazyVim defaults)
vim.api.nvim_create_autocmd("FileType", {
	group = augroup("disable_spell"),
	pattern = { "text", "plaintex", "typst", "gitcommit", "markdown" },
	callback = function()
		vim.opt_local.spell = false
	end,
})

-- Auto-reload files when changed outside Neovim (works in tmux and while idle)
vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave", "CursorHold", "CursorHoldI" }, {
	group = augroup("checktime"),
	callback = function()
		if vim.o.buftype ~= "nofile" then
			vim.cmd("checktime")
		end
	end,
})

-- Detect Helm templates early to prevent yamlls attachment
vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
	group = augroup("helm_filetype"),
	pattern = {
		"*/templates/*.yaml",
		"*/templates/*.yml",
		"*/templates/*.tpl",
	},
	callback = function()
		vim.opt_local.filetype = "helm"
	end,
})
