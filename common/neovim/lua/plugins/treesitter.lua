-- Treesitter Configuration
return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "query",
        "javascript",
        "typescript",
        "tsx",
        "json",
        "hcl",
        "terraform",
        "yaml",
        "markdown",
      },
    },
  },
}
