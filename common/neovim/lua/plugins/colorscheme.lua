return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    opts = {
      flavour = "mocha",
      integrations = {
        bufferline = false,
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        treesitter = true,
        telescope = true,
        which_key = true,
        native_lsp = {
          enabled = true,
        },
      },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")

      vim.schedule(function()
        if pcall(require, "nvim-tree") then
          vim.cmd("doautocmd ColorScheme")
        end
      end)
    end,
  },

  {
    "akinsho/bufferline.nvim",
    enabled = false,
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
