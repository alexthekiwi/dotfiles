-- Remap treesitter incremental selection to Ctrl+Up/Down
-- (Ctrl+Space conflicts with tmux prefix)
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    incremental_selection = {
      enable = true,
      keymaps = {
        init_selection = "<C-Up>",
        node_incremental = "<C-Up>",
        scope_incremental = false,
        node_decremental = "<C-Down>",
      },
    },
  },
}
