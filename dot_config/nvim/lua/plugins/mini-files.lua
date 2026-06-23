return {
  "nvim-mini/mini.files",
  keys = {
    { "<leader>fm", function()
      local name = vim.api.nvim_buf_get_name(0)
      -- Anchor on the current file if it exists on disk; otherwise fall back to
      -- Vim's tracked cwd (vim.fn.getcwd always returns a non-empty string,
      -- unlike a live vim.uv.cwd() syscall which can return "" on a buffer with
      -- no file or a flaky cwd).
      local path = (name ~= "" and vim.uv.fs_stat(name)) and name or vim.fn.getcwd()
      require("mini.files").open(path, true)
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
