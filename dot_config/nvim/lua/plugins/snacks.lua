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
    { "<leader>e", function() Snacks.explorer({ layout = { layout = { position = "right" } } }) end, desc = "Explorer (right)" },
    { "<leader>E", function() Snacks.explorer({ layout = { layout = { position = "right" } } }) end, desc = "Explorer (right)" },
  },
}
