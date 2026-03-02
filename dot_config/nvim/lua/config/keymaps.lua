-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("n", "<leader>yp", function()
  local path = vim.fn.expand("%")
  vim.fn.setreg("+", path)
  vim.notify(path, vim.log.levels.INFO, { title = "Copied path" })
end, { desc = "Yank absolute path" })

vim.keymap.set("n", "<leader>sc", function()
  vim.cmd("enew")
  vim.bo.buftype = "nofile"
  vim.bo.bufhidden = "wipe"
  vim.bo.swapfile = false
end, { desc = "Scratch buffer" })

vim.keymap.set("n", "<leader>sa", function()
  if vim.fn.expand("%") == "" or vim.bo.buftype == "nofile" then
    vim.ui.input({ prompt = "Save as: ", completion = "file" }, function(name)
      if name and name ~= "" then
        vim.bo.buftype = ""
        vim.cmd("saveas " .. vim.fn.fnameescape(name))
      end
    end)
  else
    vim.cmd("write")
  end
end, { desc = "Save / Save as" })
