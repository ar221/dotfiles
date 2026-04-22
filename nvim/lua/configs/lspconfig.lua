local defaults = require("nvchad.configs.lspconfig")
local lspconfig = require("lspconfig")

defaults.defaults()

local on_init = defaults.on_init
local capabilities = defaults.capabilities

local function custom_on_attach(client, bufnr)
  defaults.on_attach(client, bufnr)

  vim.api.nvim_set_hl(0, "LspFloatWinBorder", { fg = "#a9a1e1" })

  local border = {
    { "╭", "LspFloatWinBorder" },
    { "─", "LspFloatWinBorder" },
    { "╮", "LspFloatWinBorder" },
    { "│", "LspFloatWinBorder" },
    { "╯", "LspFloatWinBorder" },
    { "─", "LspFloatWinBorder" },
    { "╰", "LspFloatWinBorder" },
    { "│", "LspFloatWinBorder" },
  }

  vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
    border = border,
  })

  vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
    border = border,
  })
end

for _, server in ipairs({ "html", "cssls", "marksman", "somesass_ls", "bashls", "jdtls" }) do
  lspconfig[server].setup({
    on_attach = custom_on_attach,
    on_init = on_init,
    capabilities = capabilities,
  })
end

lspconfig.ts_ls.setup({
  on_attach = custom_on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = {
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact",
  },
  init_options = {
    preferences = {
      includeInlayParameterNameHints = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = true,
      includeInlayFunctionParameterTypeHints = true,
      includeInlayVariableTypeHints = true,
      includeInlayPropertyDeclarationTypeHints = true,
      includeInlayFunctionLikeReturnTypeHints = true,
      includeInlayEnumMemberValueHints = true,
      importModuleSpecifierPreference = "non-relative",
    },
  },
  settings = {
    completions = {
      completeFunctionCalls = false,
    },
  },
})

lspconfig.jsonls.setup({
  on_attach = custom_on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    json = {
      format = {
        enable = false,
      },
    },
  },
})

lspconfig.eslint.setup({
  on_attach = function(client, bufnr)
    custom_on_attach(client, bufnr)

    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = bufnr,
      command = "EslintFixAll",
    })
  end,
  on_init = on_init,
  capabilities = capabilities,
})

lspconfig.sqlls.setup({
  on_attach = custom_on_attach,
  on_init = on_init,
  capabilities = capabilities,
  filetypes = { "sql", "mysql" },
  root_dir = function()
    return vim.uv.cwd()
  end,
})

lspconfig.lua_ls.setup({
  on_attach = custom_on_attach,
  on_init = on_init,
  capabilities = capabilities,
  settings = {
    Lua = {
      diagnostics = {
        globals = {
          "vim",
          "require",
        },
      },
    },
  },
})
