local rust_analyzer = require('inlay-hints.rust_analyzer')
local internal = require('inlay-hints.__internal')
local helper = require('inlay-hints.__helper')
local cache = internal.cache
local globals = cache.opts

local M = {}

local dict = {
    rust = rust_analyzer,
}

local gen_dep_ra = function(opts)
    local ra = {
        highlight = opts.highlight,
        p_type = opts.prefix,
        p_param = opts.prefix,
        s_type = opts.suffix,
        s_param = opts.suffix,
    }
    return ra
end

local gen_dependant_opts = function()
    globals.rust_analyzer = gen_dep_ra(globals.global)
end

M.setup = function(opts, enabled)
    cache.display = enabled or true
    opts = opts or {}
    if opts.global then
        globals.global = vim.tbl_extend('force', globals.global, opts.global)
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

M.toggle = function(opts, client)
    opts = opts or globals
    local ft = vim.bo.filetype
    if dict[ft] then
        dict[ft].toggle(opts[ft], client)
    end
end

M.enable = function(opts)
    opts = opts or globals
    local ft = vim.bo.filetype
    if dict[ft] then
        dict[ft].enable(opts[ft])
    end
end

M.disable = function(bufnr)
    helper.disable_hints(bufnr)
end
return M
