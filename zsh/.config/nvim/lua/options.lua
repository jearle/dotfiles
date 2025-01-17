local o = vim.opt

o.hidden = true
o.bufhidden = 'hide'
o.number = true
o.relativenumber = true
o.expandtab = true
o.tabstop = 2
o.shiftwidth = 2
o.softtabstop = 2
o.wrap = false

-- write's a new line to the end of the file
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local n_lines = vim.api.nvim_buf_line_count(0)
    local last_line = vim.api.nvim_buf_get_lines(0, n_lines - 1, n_lines, true)[1]
    if last_line ~= "" then
      vim.api.nvim_buf_set_lines(0, n_lines, n_lines, true, {""})
    end
  end,
})

