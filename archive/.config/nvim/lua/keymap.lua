local map = vim.api.nvim_set_keymap

map('n', '<Space>', '', {})

vim.g.mapleader = ' '

local options = { noremap = true, silent = true }

map('n', '<leader>w', ':w<cr>', options)
map('n', '<leader>quit', ':q<cr>', options)
map('n', '<leader>e', ':Ex!<cr>', options)
map('n', '<leader>bn', ':bn<cr>', options)
map('n', '<leader>bp', ':bp<cr>', options)

map("n", "y", '"+y', options)
map("v", "y", '"+y', options)

map("n", "p", '"+p', options)
map("v", "p", '"+p', options)

map('n', 'x', '"+x', options)
map('v', 'x', '"+x', options)

map('n', 'd', '"+d', options)
map('v', 'd', '"+d', options)

