-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Prefer .git as root marker over package.json so monorepos resolve to the repo root
vim.g.root_spec = { { ".git", "lua" }, "lsp", "cwd" }

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function()
    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = { current_line = true },
    })
  end,
})
