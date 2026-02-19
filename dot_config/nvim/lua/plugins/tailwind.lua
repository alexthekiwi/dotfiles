-- Override tailwindcss LSP root detection for monorepos
-- Default finds the nearest package.json, missing cross-package CSS configs
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      tailwindcss = {
        root_dir = function(fname)
          local util = require("lspconfig.util")
          return util.root_pattern(".git")(fname)
            or util.root_pattern("tailwind.config.js", "tailwind.config.cjs", "tailwind.config.mjs", "tailwind.config.ts")(fname)
            or util.root_pattern("package.json")(fname)
        end,
      },
    },
  },
}
