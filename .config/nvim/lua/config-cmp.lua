local cmp = require('cmp')

cmp.setup({
  sources = cmp.config.sources({
    {name = 'nvim_lsp'},
    -- {name = 'vsnip'},
    -- {name = 'luasnip'},
  }),
  snippet = {
    expand = function(args)
      -- vim.fn["vsnip#anonymous"](args.body) -- For `vsnip` users.
      -- require('luasnip').lsp_expand(args.body) -- For `luasnip` users.
      -- You need Neovim v0.10 to use vim.snippet
      vim.snippet.expand(args.body)
    end,
  },
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true }),
  }),
})

