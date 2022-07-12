local M = {}

M.get_last_line = function(bufnr)
    return vim.api.nvim_buf_line_count(bufnr) - 1
end

M.disable_hints = function(bufnr, ns)
    vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
end

-- Cantor Pairing function
-- See https://en.wikipedia.org/wiki/Pairing_function
M.get_id = function(x, y)
    return (
        x * x
            + 3 * x
            + 2 * x * y
            + y
            + y * y
        ) / 2
end

return M
