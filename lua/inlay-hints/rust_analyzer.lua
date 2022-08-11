local internal = require 'inlay-hints.__internal'
local helper = require 'inlay-hints.__helper'
local log = internal.log
local cache = internal.cache

local M = {}

-- Only internal.rust_analyzer type opts, no globals
M.__cachedopts = nil

local callback = function(err, result, ctx)
  local bufnr = ctx.bufnr
  M.__cachedopts = M.__cachedopts or {}
  local config = M.__cachedopts.opts or cache.opts.rust_analyzer
  if err then
    -- internal.log_file('\nCallback Error')
    -- Retry when cargo check is done
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    internal.create_retry_autocmd(client, bufnr, M.__send_request)
    return
  end
  M.__cachedopts = nil
  -- internal.log_file('\nRequest Successful')

  local display = cache.display
  local ns_id = internal.namespace
  helper.disable_hints(bufnr, ns_id)
  for _, entry in ipairs(result) do
    local pos = entry.position
    local vtext_id = helper.get_id(pos.line, pos.character)
    if display then
      local label = ''
      if entry.kind == 1 then --type
        local opt = config.kinds.type
        label = opt.prefix .. entry.tooltip .. opt.suffix
      elseif entry.kind == 2 then --parameter
        local opt = config.kinds.parameter
        label = opt.prefix .. entry.tooltip .. opt.suffix
      else -- other
        label = entry.label
      end

      local opts = {
        id = vtext_id,
        virt_text = { { label, config.highlight } },
        virt_text_pos = 'eol',
      }
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, pos.line, pos.character, opts)
    else
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    end
  end
end

M.__send_request = function(client, bufnr)
  local lastline = helper.get_last_line(bufnr)
  local lastcolnum = #vim.api.nvim_buf_get_lines(bufnr, -2, -1, false)[1]
  local params = {
    textDocument = vim.lsp.util.make_text_document_params(bufnr),
    range = {
      start = {
        line = 0,
        character = 0,
      },
      ['end'] = {
        line = lastline,
        character = lastcolnum,
      },
    },
  }

  -- internal.log_file('Request sent')
  client.request('textDocument/inlayHint', params, callback, bufnr)
end

M.on_attach = function(client, bufnr)
  internal.create_reload_autocmd(client, bufnr, M.__send_request)
  if internal.cache.display then
    M.enable(nil, client)
  end
end

---Enables inlay hints in buffer bufnr
---@param opts table|none
---@param client any
M.enable = function(opts, client)
  local bufnr = vim.api.nvim_get_current_buf()
  cache.display = true
  M.__cachedopts = {
    bufnr = bufnr,
    opts = opts or cache.opts.rust_analyzer,
  }
  if client then
    M.__send_request(client, bufnr)
  else
    local clients = vim.lsp.get_active_clients {
      bufnr = bufnr,
      name = 'rust_analyzer',
    }
    if #clients >= 1 then
      M.__send_request(clients[1], bufnr)
    else
      log 'No LSP found'
    end
  end
end

---Disables inlay hints in buffer bufnr
---@param bufnr buffer
M.disable = function(bufnr)
  internal.cache.display = false
  local ns = internal.namespace
  helper.disable_hints(bufnr, ns)
end

---Toggles inlay hints in buffer bufnr
---@param opts table
---@param client any
M.toggle = function(opts, client)
  local bufnr = vim.api.nvim_get_current_buf()
  M.__cachedopts = {
    bufnr = bufnr,
    opts = opts or cache.opts.rust_analyzer,
  }

  if cache.display then
    M.disable(bufnr)
  else
    M.enable(opts, client)
  end
end

return M
