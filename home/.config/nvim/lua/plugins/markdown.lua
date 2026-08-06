return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = { 'markdown' },
    opts = {},  -- in-buffer rendering: headings, tables, checkboxes, code blocks
    config = function(_, opts)
      require('render-markdown').setup(opts)
      -- nvim 0.12 ships the markdown parsers but does not start them by default
      vim.api.nvim_create_autocmd('FileType', {
        pattern = 'markdown',
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
}
