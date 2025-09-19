local keymap = vim.keymap.set
keymap("n", "<leader><leader>", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
keymap("n", "<leader>/", "<cmd>Telescope live_grep<cr>", { desc = "Search in files" })
keymap("n", "<leader>b", "<cmd>Telescope buffers<cr>", { desc = "Switch buffer" })
keymap("n", "<leader>:", "<cmd>Telescope commands<cr>", { desc = "Commands" })

keymap("n", "<leader>e", "<cmd>NvimTreeToggle<cr>", { desc = "Toggle file explorer" })
keymap("n", "<leader>E", "<cmd>NvimTreeFindFile<cr>", { desc = "Find current file in explorer" })
keymap("n", "<leader>r", "<cmd>NvimTreeRefresh<cr>", { desc = "Refresh file explorer" })

keymap("n", "<leader>w", "<cmd>w<cr>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>q<cr>", { desc = "Quit" })
-- Use LazyVim's Snacks.bufdelete() for proper buffer management
keymap("n", "<leader>x", function()
	require("snacks").bufdelete()
end, { desc = "Close buffer" })

keymap("n", "<C-h>", "<C-w>h", { desc = "Go to left window" })
keymap("n", "<C-j>", "<C-w>j", { desc = "Go to lower window" })
keymap("n", "<C-k>", "<C-w>k", { desc = "Go to upper window" })
keymap("n", "<C-l>", "<C-w>l", { desc = "Go to right window" })

keymap("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

keymap({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

keymap("n", "<A-j>", "<cmd>m .+1<cr>==", { desc = "Move down" })
keymap("n", "<A-k>", "<cmd>m .-2<cr>==", { desc = "Move up" })
keymap("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move down" })
keymap("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move up" })
keymap("v", "<A-j>", ":m '>+1<cr>gv=gv", { desc = "Move down" })
keymap("v", "<A-k>", ":m '<-2<cr>gv=gv", { desc = "Move up" })

-- Git menu - <leader>g prefix
-- Note: GitHub-specific mappings are defined in lua/plugins/git.lua
-- This creates the git menu group for which-key
keymap("n", "<leader>g", "", { desc = "+git" })
