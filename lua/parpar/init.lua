-- requiring for side-effects, exposes `parinfer` global
require("parinfer.setup")

local paredit = require("nvim-paredit")
local paredit_defaults = require("nvim-paredit.defaults")

local function pause()
  if vim.b.parinfer_enabled then
    local prev_mode = vim.g.parinfer_mode
    vim.b.parinfer_enabled = false
    return function()
      vim.g.parinfer_mode = "paren"
      vim.b.parinfer_enabled = true
      -- "parinfer.setup" exposes parinfer global
      --- @diagnostic disable-next-line: undefined-global
      parinfer.text_changed(vim.fn.bufnr())
      vim.g.parinfer_mode = prev_mode
    end
  else
    return function() end
  end
end

local function wrap(f)
  -- Q: should we take and forward additional fn arguments?
  return function()
    local resume = pause()
    local result = pcall(f)
    resume()
    return result;
  end
end

local function setup(opts)
  opts = opts or {}
  local paredit_opts = opts.paredit or {}
  local keys = paredit_opts.keys or {}

  if paredit_opts.use_default_keys ~= false then
    keys = vim.tbl_extend("force", paredit_defaults.default_keys, keys)
  end

  local wrapped_keys = {}
  for k, v in pairs(keys) do
    -- We want to wrap edit operations, but wrapping movement is unnecessary.
    -- Assumption is that edits are flagged as repeatable, so by not wrapping
    -- unrepeatable we should avoid wrapping movements.
    if v.repeatable ~= false then
      -- first item is callback, override it with wrapped function
      v = vim.tbl_extend("force", v, { [1] = wrap(v[1]) })
    end
    wrapped_keys[k] = v
  end

  paredit.setup(vim.tbl_extend("force", paredit_opts, { keys = wrapped_keys }))
end

return {
  setup = setup,
  wrap = wrap,
  pause = pause,
}
