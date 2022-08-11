local rust_analyzer = require 'inlay-hints.rust_analyzer'
local internal = require 'inlay-hints.__internal'
local helper = require 'inlay-hints.__helper'
local cache = internal.cache
local globals = cache.opts

local M = {}

local dict = {
  rust = rust_analyzer,
}

-- Generates Rust-analyzer dependant options
--- @param opts table
--- @return table Generated options
local gen_dep_ra = function(opts)
  local ra = {
    highlight = opts.highlight,
    kinds = {
      type = {
        prefix = opts.kinds.type.prefix,
        suffix = opts.kinds.type.suffix,
      },
      parameter = {
        prefix = opts.kinds.parameter.prefix,
        suffix = opts.kinds.parameter.suffix,
      },
    },
  }
  return ra
end

-- Generates Rust-Analyzer dependant options
--- @see |gen_dep_ra()|
local gen_dependant_opts = function()
  globals.rust_analyzer = gen_dep_ra(globals.global)
end

-- Setups inlay-hints plugin
--- @param opts table Plugin options
--- @param enabled boolean Whether it displays inlay hints or not
M.setup = function(opts, enabled)
  cache.display = enabled or true
  opts = opts or {}
  if opts.global then
    globals.global = vim.tbl_deep_extend('force', globals.global, opts.global)
  end

  internal.create_namespace()

  gen_dependant_opts()

  if opts.rust_analyzer then
    globals.rust_analyzer = vim.tbl_deep_extend('force', globals.rust_analyzer, opts.rust_analyzer)
  end
end

M.on_attach = function(client, bufnr)
  local ft = vim.api.nvim_buf_get_option(bufnr, 'filetype')
  if dict[ft] then
    dict[ft].on_attach(client, bufnr)
  end
end

-- Toggles inlay hints in buffer
---@param opts table
---@param client any
M.toggle = function(opts, client)
  opts = opts or globals
  local ft = vim.bo.filetype
  if dict[ft] then
    dict[ft].toggle(opts[ft], client)
  end
end

-- Enables inlay hints in buffer
---@param opts table
M.enable = function(opts)
  opts = opts or globals
  local ft = vim.bo.filetype
  if dict[ft] then
    dict[ft].enable(opts[ft])
  end
end

-- Disables inlay hints in buffer bufnr
---@param bufnr buffer
M.disable = function(bufnr)
  local ns_id = internal.namespace
  helper.disable_hints(bufnr, ns_id)
end
return M
