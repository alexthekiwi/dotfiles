return {
  "nvim-lualine/lualine.nvim",
  opts = function(_, opts)
    -- Remove lazy updates count and time from right side
    opts.sections.lualine_x = vim.tbl_filter(function(comp)
      if type(comp) == "table" and comp[1] then
        local fn_str = tostring(comp[1])
        if fn_str:match("lazy") then return false end
      end
      return true
    end, opts.sections.lualine_x or {})

    -- Keep position and location, remove time
    opts.sections.lualine_y = { "progress" }
    opts.sections.lualine_z = { "location" }
  end,
}
