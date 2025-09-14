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
        "go",
        "gomod",
        "gowork",
        "terraform",
        "yaml",
        "markdown",
        "dockerfile",
      },
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = {
        enable = true,
      },
      incremental_selection = {
        enable = true,
      },
    },
  },
}
