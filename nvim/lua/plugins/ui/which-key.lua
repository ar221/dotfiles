---@type wk.Win.opts
return {
  "folke/which-key.nvim",
  keys = { "<leader>", "<c-r>", "<c-w>", '"', "'", "`", "c", "v", "g" },
  cmd = "WhichKey",
  opts = {
    preset = "helix",
  },
  config = function(_, opts)
    dofile(vim.g.base46_cache .. "whichkey")
    local wk = require("which-key")

    wk.setup(opts)
    wk.add({
      { "<leader>o", group = "vault" },
      { "<leader>oj", group = "journal" },
    })
  end,
}
