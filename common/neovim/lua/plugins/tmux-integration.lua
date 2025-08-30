return {
  {
    "christoomey/vim-tmux-navigator",
    event = "VeryLazy",
    keys = {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Go to left pane" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Go to bottom pane" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Go to top pane" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Go to right pane" },
    },
    config = function()
      vim.g.tmux_navigator_no_mappings = 1
      vim.g.tmux_navigator_save_on_switch = 2
      vim.g.tmux_navigator_disable_when_zoomed = 1
    end,
  },
}
