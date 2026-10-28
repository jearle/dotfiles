-- Minimal config: built-in LSP, treesitter highlighting, no plugin manager.

vim.g.mapleader = " "

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.tabstop = 2
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.undofile = true
vim.opt.clipboard = "unnamedplus"

vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Save" })

-- Treesitter highlighting wherever a parser is available.
vim.api.nvim_create_autocmd("FileType", {
  callback = function(args)
    pcall(vim.treesitter.start, args.buf)
  end,
})

-- Language servers (binaries from mise: config.toml).
vim.lsp.config("lua_ls", {
  cmd = { "lua-language-server" },
  filetypes = { "lua" },
  root_markers = { ".luarc.json", ".git" },
  settings = { Lua = { diagnostics = { globals = { "vim" } } } },
})

-- TypeScript 7 native language server.
vim.lsp.config("typescript", {
  cmd = { "tsc", "--lsp", "--stdio" },
  filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact" },
  root_markers = { "tsconfig.json", "package.json", ".git" },
})

vim.lsp.enable({ "lua_ls", "typescript" })

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    local opts = { buffer = args.buf }
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
    vim.keymap.set("n", "<leader>r", vim.lsp.buf.rename, opts)
    vim.keymap.set("n", "<leader>a", vim.lsp.buf.code_action, opts)
  end,
})
