return {
  "echasnovski/mini.files",
  keys = {
    { "<leader>fm", function() require("mini.files").open(vim.api.nvim_buf_get_name(0), true) end, desc = "Mini Files (current file)" },
    { "<leader>fM", function() require("mini.files").open(vim.uv.cwd(), true) end, desc = "Mini Files (cwd)" },
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
