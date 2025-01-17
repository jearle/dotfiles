local configs = require('nvim-treesitter.configs')

configs.setup({
  ensure_installed = {
    'c',
    'cpp',
    'c_sharp',
    'css',
    'go',
    'html',
    'javascript',
    'json',
    'json5',
    'lua',
    'python',
    'ruby',
    'rust',
    'scss',
    'styled',
    'tsx',
    'typescript',
    'zig',
  },

  highlight = {
    enable = true,
  },
})

