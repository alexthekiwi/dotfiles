-- Remap treesitter incremental selection to Ctrl+Up/Down
-- (Ctrl+Space conflicts with tmux prefix)
return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "typescript", "tsx", "javascript", "php", "php_only",
      "html", "css", "json", "yaml", "bash", "lua", "markdown", "twig",
    },
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
