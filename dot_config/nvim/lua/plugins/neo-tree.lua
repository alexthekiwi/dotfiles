return {
  "nvim-neo-tree/neo-tree.nvim",
  opts = {
    window = {
      position = "right",
    },
  },
  keys = {
    { "<leader>e", "<cmd>Neotree toggle position=right<cr>", desc = "Explorer (right)" },
  },
}
