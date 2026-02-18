return {
  "folke/snacks.nvim",
  opts = {
    dashboard = {
      preset = {
        header = "",
      },
    },
    explorer = {
      replace_netrw = true,
    },
  },
  keys = {
    { "<leader>e", function() Snacks.explorer.open({ position = "right" }) end, desc = "Explorer (right)" },
    { "<leader>E", function() Snacks.explorer.open({ position = "right" }) end, desc = "Explorer (right)" },
  },
}
