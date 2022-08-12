local internal = require 'inlay-hints.__internal'
local helper = require 'inlay-hints.__helper'
local cache = internal.cache
local globals = cache.opts

local M = {}

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
--- @param opts table|none Plugin options
--- @param enabled boolean|none Whether it displays inlay hints or not
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

M.client_has_inlay_hints = function(client)
  return client.server_capabilities.inlayHintProvider
end

M.on_attach = function(client, bufnr)
  if M.client_has_inlay_hints(client) then
    internal.on_attach(client, bufnr)
  end
end

-- Toggles inlay hints in buffer
---@param opts table
---@param client any
M.toggle = function(opts, client)
  opts = opts or globals
  local ft = vim.bo.filetype
  internal.toggle(opts[ft], client)
end

-- Enables inlay hints in buffer
---@param opts table
M.enable = function(opts)
  opts = opts or globals
  local ft = vim.bo.filetype
  internal.enable(opts[ft])
end

-- Disables inlay hints in buffer bufnr
---@param bufnr buffer
M.disable = function(bufnr)
  local ns_id = internal.namespace
  helper.disable_hints(bufnr, ns_id)
end
return M
