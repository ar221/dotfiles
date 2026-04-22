return {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    opts = require "configs.conform",
    config = function(_, opts)
      require("conform").setup(opts)
    end,
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  -- test new blink
  -- { import = "nvchad.blink.lazyspec" },

  { import = "plugins.ui.snacks" },
  { import = "plugins.ui.noice" },
  { import = "plugins.ui.which-key" },
  { import = "plugins.ui.todo-comments" },
  { import = "plugins.obsidian" },



  { import = "plugins.utils.persistence" },



  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("configs.treesitter")
    end,
  },

}
