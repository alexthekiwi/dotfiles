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
      hidden = true,
      ignored = true,
    },
    picker = {
      sources = {
        files = {
          hidden = true,
          ignored = true,
          exclude = { "node_modules", "vendor", ".git", ".next", ".nuxt", ".output", "dist", "build" },
        },
        grep = {
          hidden = true,
          ignored = true,
          exclude = { "node_modules", "vendor", ".git", ".next", ".nuxt", ".output", "dist", "build" },
        },
      },
    },
  },
  keys = {
    { "<leader>e", function() Snacks.explorer({ layout = { layout = { position = "right" } } }) end, desc = "Explorer (right)" },
    { "<leader>E", function() Snacks.explorer({ layout = { layout = { position = "right" } } }) end, desc = "Explorer (right)" },
  },
}
