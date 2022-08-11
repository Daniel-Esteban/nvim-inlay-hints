Very WIP
====

Adds Inlay hint support to Neovim

## Minimal Configuration:
```lua
local ih = require 'inlay-hints'
ih.setup()
ih.on_attach(client, bufnr)

lspconfig.rust_analyzer.setup {
  on_attach = ih.on_attach(client, bufnr),
}
```

## Example Configuration
```lua
local ih = require 'inlay-hints'
ih.setup {
  global = {
    highlight = 'Purple',
    kinds = {
      type = {
        prefix = '[',
        suffix = ']',
      },
      parameter = {
        prefix = '(',
        suffix = ')',
      },
    },
  },
}
local rust_attach = function(client, bufnr)
  -- ...
  ih.on_attach(client, bufnr)
end

lspconfig.rust_analyzer.setup {
  on_attach = rust_attach,
  capabilities = --- capabilities,
}

vim.keymap.set('n', '<leader>i', ih.toggle, { desc = 'Toggle Rust Inlay Hints' })
```
