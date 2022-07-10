local M = {}
M.__x = { display = false }

local log = function(str)
    print('NVIM-INLINE-HINTS: ' .. str)
end

local callback = function(_, result)
    local display = M.__x.display
    local bufnr = vim.api.nvim_get_current_buf()
    for _, entry in ipairs(result) do
        local pos = entry.position
        local ns = 'ih' .. pos.line .. ',' .. pos.character
        local ns_id = vim.api.nvim_create_namespace(ns)
        if display then

            local opts = {
                id = ns_id,
                virt_text = { { entry.label, "Comment" } },
                virt_text_pos = 'eol',
            }
            vim.api.nvim_buf_set_extmark(
                bufnr,
                ns_id,
                pos.line,
                pos.character,
                opts
            )
        else
            vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
        end
    end

end

M.toggle_inlay_hints = function()
    M.__x.display = not M.__x.display
    local bufnr = vim.api.nvim_get_current_buf()
    local linenum = vim.api.nvim_buf_line_count(bufnr)
    local lastcolnum = #vim.api.nvim_buf_get_lines(bufnr, linenum - 1, linenum, false)[1]
    local params = {
        textDocument = vim.lsp.util.make_text_document_params(bufnr),
        range = {
            start = {
                line = 1,
                character = 0
            },
            ['end'] = {
                line = linenum - 1, -- -1 or not?
                character = lastcolnum
            },
        }
    }

    local clients = vim.lsp.get_active_clients({ bufnr = bufnr, name = 'rust_analyzer' })

    if #clients >= 1 then
        clients[1].request('textDocument/inlayHint', params, callback, bufnr)
    else
        log('No LSP found')
    end
end

return M
