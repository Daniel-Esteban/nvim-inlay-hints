local M = {}
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
local opts = {
  global = g_opts,
  rust_analyzer = ra_opts,
}
M.cache = {
  display = true,
  opts = opts,
}

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
      -- local fetching = progress['rustAnalyzer/Fetching'] or {}
      -- local indexing = progress['rustAnalyzer/Indexing'] or {}
      -- local loading = progress['rustAnalyzer/Loading'] or {}
      -- local roots = progress['rustAnalyzer/Roots Scanned'] or {}
      local check = progress['rustAnalyzer/cargo check'] or {}
      if
        check.done
        -- and indexing.done
        -- and indexing.percentage == 100
        -- and loading.done
        -- and roots.done
        -- and fetching.done
      then
        -- self delete autocmd
        vim.api.nvim_del_augroup_by_id(augroup)

        M.log_file '\nRetry Finished'
        requestfunc(client, bufnr)
      end
    end,
  })
end

return M
