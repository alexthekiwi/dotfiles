return {
  "nvim-mini/mini.files",
  keys = {
    { "<leader>fm", function()
      local name = vim.api.nvim_buf_get_name(0)
      require("mini.files").open(name ~= "" and name or (vim.uv or vim.loop).cwd(), true)
    end, desc = "Mini Files (current file)" },
    { "<leader>fM", function() require("mini.files").open(LazyVim.root(), true) end, desc = "Mini Files (root)" },
  },
  opts = {
    mappings = {
      go_in = "l",
      go_in_plus = "<CR>",
      go_out = "h",
      go_out_plus = "H",
    },
    windows = {
      preview = true,
      width_preview = 40,
    },
  },
}
