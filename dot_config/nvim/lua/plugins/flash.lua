return {
  "folke/flash.nvim",
  -- Disable flash's treesitter-select mappings. They crash on small buffers
  -- (scratch/notes files) via treesitter.lua:78 "attempt to get length of nil
  -- 'line'" and leave stale labels painted across buffers. Plain `s` jump stays.
  keys = {
    { "S", false, mode = { "n", "x", "o" } },
    { "R", false, mode = { "o", "x" } },
  },
}
