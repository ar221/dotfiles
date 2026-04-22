require "nvchad.autocmds"

vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = vim.fn.expand("~/.config/kitty/kitty.conf"),
  callback = function()
    vim.system({ "pkill", "-SIGUSR1", "kitty" })
  end,
})
