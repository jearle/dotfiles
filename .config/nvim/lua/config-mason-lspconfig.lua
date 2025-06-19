local mason_lspconfig = require('mason-lspconfig')
local lspconfig = require('lspconfig')

mason_lspconfig.setup({
  ensure_installed = {
    'ts_ls',
    'ruby_lsp',
    'lua_ls',
    'gopls',
    'clangd',
    'bashls',
    'yamlls',
  }
})

local map_lspconfig_setup_options = {
  lua_ls = {
    settings = {
      Lua = {
        diagnostics = {
          globals = { 'vim', },
        },
      },
    }
  },

  gopls = {
    settings = {
      gopls = {
        usePlaceholders = true,
      },
    },
  },
}

mason_lspconfig.setup_handlers({
  function(server_lsp)
    local lspconfig_setup_options = map_lspconfig_setup_options[server_lsp] or {}

    lspconfig[server_lsp].setup(lspconfig_setup_options)
  end,
})

