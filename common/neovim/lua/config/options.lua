local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.termguicolors = true
opt.mouse = "a"
opt.clipboard = "unnamedplus"
opt.ignorecase = true
opt.smartcase = true
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = 2
opt.autoindent = true
opt.smartindent = true
opt.wrap = false
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.updatetime = 250
opt.timeoutlen = 300
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10
opt.conceallevel = 2
opt.undofile = true
opt.backup = false
opt.writebackup = false
opt.swapfile = false

opt.colorcolumn = "80"

opt.signcolumn = "yes"
opt.statuscolumn = "%s%=%{&ft=='NvimTree'?'':v:relnum?v:relnum:v:lnum}   "
opt.ttyfast = true
opt.lazyredraw = false

opt.shortmess:append("I")
opt.spell = false

-- Cursor configuration - pink blinking cursor
opt.guicursor = {
	"n-v-c:block-Cursor/lCursor-blinkwait1000-blinkon500-blinkoff500",
	"i-ci:ver25-Cursor/lCursor-blinkwait1000-blinkon500-blinkoff500",
	"r-cr:hor20-Cursor/lCursor-blinkwait1000-blinkon500-blinkoff500",
}

-- Cursor color is set in colorscheme.lua after theme loads
