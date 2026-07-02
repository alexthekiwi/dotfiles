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
    image = { enabled = false },
    picker = {
      sources = {
        files = {
          hidden = false,
          ignored = false,
          exclude = { "node_modules", "vendor", ".git", ".next", ".nuxt", ".output", "dist", "build" },
        },
        grep = {
          hidden = false,
          ignored = false,
          exclude = { "node_modules", "vendor", ".git", ".next", ".nuxt", ".output", "dist", "build" },
        },
        explorer = {
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
    {
      "<leader>sG",
      function()
        vim.ui.input({ prompt = "Grep in glob: " }, function(glob)
          if glob and glob ~= "" then Snacks.picker.grep({ glob = glob }) end
        end)
      end,
      desc = "Grep in glob",
    },
    { "<leader>fh", function() Snacks.picker.files({ hidden = true, ignored = true }) end, desc = "Find files (hidden + ignored)" },
  },
}
