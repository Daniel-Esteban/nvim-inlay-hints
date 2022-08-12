local M = {}

local helper = require 'inlay-hints.__helper'

M.debug_file = false

M.log = function(str)
  print('NVIM-INLINE-HINTS: ' .. str)
end

M.log_file = function(str)
  if not M.debug_file then
    return
  end
  local f = io.open('inlay_hints_log.txt', 'a+')
  if f then
    f:write(str .. '\n')
    f:close()
  end
end

local g_opts = {
  highlight = 'Comment',
  kinds = {
    type = {
      prefix = ': ',
      suffix = '',
    },
    parameter = {
      prefix = '`',
      suffix = '`',
    },
  },
}
local ra_opts = {}
local plugin_opts = {
  global = g_opts,
  rust_analyzer = ra_opts,
}
M.cache = {
  display = true,
  opts = plugin_opts,
}

M.cachedopts = nil

M.P = function(str)
  print(vim.inspect(str))
end

M.namespace = nil

M.create_namespace = function()
  M.namespace = vim.api.nvim_create_namespace 'inlay-hints'
end

M.PF = function(str)
  M.log_file(vim.inspect(str))
end

M.create_reload_autocmd = function(client, bufnr, requestfunc)
  local augroup = vim.api.nvim_create_augroup('IHReload', { clear = true })
  vim.api.nvim_create_autocmd('BufWritePost', {
    group = augroup,
    buffer = bufnr,
    desc = 'Inlay-Hints updater',
    callback = function()
      M.log_file '\nReloading Inlay-Hints'
      requestfunc(client, bufnr)
    end,
  })
end

M.create_retry_autocmd = function(client, bufnr, requestfunc)
  local augroup = vim.api.nvim_create_augroup('IHProgress', { clear = true })
  vim.api.nvim_create_autocmd('User LspProgressUpdate', {
    group = augroup,
    buffer = bufnr,
    desc = 'Inlay-Hints Progress Trigger',
    callback = function()
      if not M.cache.display then
        return
      end

      local progress = client.messages.progress
      local check = progress['rustAnalyzer/cargo check'] or {}
      if check.done then
        -- self delete autocmd
        vim.api.nvim_del_augroup_by_id(augroup)

        M.log_file '\nRetry Finished'
        requestfunc(client, bufnr)
      end
    end,
  })
end

local callback = function(err, result, ctx)
  local bufnr = ctx.bufnr
  M.cachedopts = M.cachedopts or {}
  local config = M.cachedopts.opts or M.cache.opts.global
  if err then
    M.log_file '\nCallback Error'
    M.PF(err)
    M.log_file '\nend error\n'
    -- Retry when cargo check is done
    local client = vim.lsp.get_client_by_id(ctx.client_id)
    M.create_retry_autocmd(client, bufnr, M.send_request)
    return
  end
  M.cachedopts = nil
  M.log_file '\nRequest Successful\n'
  M.PF(result)
  M.log_file '\nend result\n'
  M.PF(err)
  M.log_file '\nend error\n'
  M.PF(ctx)
  M.log_file '\nend ctx\n'

  local display = M.cache.display
  local ns_id = M.namespace
  helper.disable_hints(bufnr, ns_id)
  if not result then
    return
  end
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

      local extmark_opts = {
        id = vtext_id,
        virt_text = { { label, config.highlight } },
        virt_text_pos = 'eol',
      }
      vim.api.nvim_buf_set_extmark(bufnr, ns_id, pos.line, pos.character, extmark_opts)
    else
      vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
    end
  end
end

M.send_request = function(client, bufnr)
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

---Disables inlay hints in buffer bufnr
---@param bufnr buffer
M.disable = function(bufnr)
  M.cache.display = false
  local ns = M.namespace
  helper.disable_hints(bufnr, ns)
end

---Enables inlay hints in buffer bufnr
---@param opts table|none
---@param client any
M.enable = function(opts, client)
  local bufnr = vim.api.nvim_get_current_buf()
  M.cache.display = true
  M.cachedopts = {
    bufnr = bufnr,
    opts = opts or M.cache.opts.global,
  }
  if client then
    M.send_request(client, bufnr)
  else
    local clients = vim.lsp.get_active_clients {
      bufnr = bufnr,
    }
    if #clients >= 1 then
      M.send_request(clients[1], bufnr)
    else
      M.log 'No LSP found'
    end
  end
end

---Toggles inlay hints in buffer bufnr
---@param opts table
---@param client any
M.toggle = function(opts, client)
  local bufnr = vim.api.nvim_get_current_buf()
  M.cachedopts = {
    bufnr = bufnr,
    opts = opts or M.cache.opts.global,
  }

  if M.cache.display then
    M.disable(bufnr)
  else
    M.enable(opts, client)
  end
end

M.on_attach = function(client, bufnr)
  M.create_reload_autocmd(client, bufnr, M.send_request)
  if M.cache.display then
    M.log_file 'Display enabled by default'
    M.enable(nil, client)
  end
end

return M
