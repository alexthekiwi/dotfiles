vim.g.lazyvim_php_lsp = "intelephense"

vim.lsp.config("laravel_lsp", {
  cmd = { "laravel-lsp" },
  filetypes = { "php", "blade" },
  root_markers = { "artisan", "composer.json", ".git" },
})

vim.lsp.enable("laravel_lsp")

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
