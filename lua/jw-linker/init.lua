local parser = require("jw-linker.parser")
local url = require("jw-linker.url")

local M = {}

M.defaults = {
  -- Which template from `templates` is used for inserted links.
  target = "jwlibrary",
  -- Template used when opening a passage; nil = same as `target`.
  -- E.g. insert `jwlibrary` links but open them on jw.org in the browser.
  open_target = nil,
  -- wtlocale: "X" = German, "E" = English, ...
  locale = "X",
  -- Publication symbol, e.g. "nwtsty" (study edition); nil = app default.
  pub = nil,
  -- Book name languages to recognise; earlier ones win on ambiguous abbreviations.
  languages = { "de", "en" },
  -- URL templates. Placeholders: {bible} {book} {book2} {chapter} {verse}
  -- {end_chapter} {end_verse} {locale} {pub} {pub_param} {ref}.
  -- A template may also be `function(ref, vars) return url end`.
  templates = {
    jwlibrary = "jwlibrary:///finder?srcid=jwlshare&wtlocale={locale}&prefer=lang&bible={bible}{pub_param}",
    jworg = "https://www.jw.org/finder?srcid=jwlshare&wtlocale={locale}&prefer=lang&bible={bible}{pub_param}",
    wol = "https://wol.jw.org/finder?wtlocale={locale}&bible={bible}{pub_param}",
    pergament = url.pergament,
  },
  -- "[{label}]({url})" with {label} and {url}, or function(label, url, ref).
  link_format = "[{label}]({url})",
  -- Command used to open URLs, e.g. { "xdg-open" }; nil = vim.ui.open().
  open_cmd = nil,
  -- Filetypes that get the buffer-local keymaps; empty = set them globally.
  filetypes = { "markdown" },
  -- Set any entry to false to disable it.
  keymaps = {
    insert_link = "<C-g>l", -- insert mode: link the reference just typed
    insert_link_open = "<C-g>o", -- insert mode: link it and open the passage
    link = "<leader>jl", -- normal/visual: link reference under cursor/selection
    link_open = "<leader>jo", -- normal/visual: link and open
    open = "<leader>jg", -- normal: open link/reference under cursor
  },
}

M.config = vim.deepcopy(M.defaults)

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.WARN, { title = "jw-linker" })
end

--- Build the URL for a reference string or parsed reference.
---@param ref string|JwRef
---@param target? string
---@return string|nil, string|nil
function M.url(ref, target)
  if type(ref) == "string" then
    local parsed = parser.parse(ref, M.config.languages)
    if not parsed then
      return nil, ("jw-linker: could not parse %q"):format(ref)
    end
    ref = parsed
  end
  return url.build(ref, target or M.config.target, M.config)
end

local function format_link(ref, link_url)
  local fmt = M.config.link_format
  if type(fmt) == "function" then
    return fmt(ref.label, link_url, ref)
  end
  return url.expand(fmt, { label = ref.label, url = link_url })
end

function M.open_url(target_url)
  local cmd = M.config.open_cmd
  if cmd then
    cmd = type(cmd) == "string" and { cmd } or vim.deepcopy(cmd)
    table.insert(cmd, target_url)
    vim.system(cmd, { detach = true })
    return
  end
  local _, err = vim.ui.open(target_url)
  if err then
    notify(err, vim.log.levels.ERROR)
  end
end

local function open_ref(ref)
  local u, err = url.build(ref, M.config.open_target or M.config.target, M.config)
  if not u then
    return notify(err, vim.log.levels.ERROR)
  end
  M.open_url(u)
end

--- Replace bytes [s, e] (1-based, inclusive) of `row` with a link for `ref`.
--- Returns the 0-based column right after the inserted link.
local function replace(row, s, e, ref)
  local u, err = url.build(ref, M.config.target, M.config)
  if not u then
    notify(err, vim.log.levels.ERROR)
    return nil
  end
  local link = format_link(ref, u)
  vim.api.nvim_buf_set_text(0, row - 1, s - 1, row - 1, e, { link })
  return s - 1 + #link
end

local function already_linked(line, m)
  return line:sub(m.s - 1, m.s - 1) == "[" and line:sub(m.e + 1, m.e + 2) == "]("
end

--- Insert mode: link the reference that ends right before the cursor.
---@param opts? { open?: boolean }
function M.link_before_cursor(opts)
  opts = opts or {}
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local before = line:sub(1, col)
  local trimmed = before:gsub("%s+$", "")
  local m = parser.ending_at(trimmed, #trimmed, M.config.languages)
  if not m then
    return notify("jw-linker: no scripture reference before cursor")
  end
  local after = replace(row, m.s, m.e, m.ref)
  if after then
    vim.api.nvim_win_set_cursor(0, { row, after + (#before - #trimmed) })
    if opts.open then
      open_ref(m.ref)
    end
  end
end

--- Insert a link for `text` at the cursor (used by `:JWLink Joh 3:16`).
---@param opts? { open?: boolean }
function M.insert(text, opts)
  opts = opts or {}
  local ref = parser.parse(text, M.config.languages)
  if not ref then
    return notify(("jw-linker: could not parse %q"):format(text))
  end
  local u, err = url.build(ref, M.config.target, M.config)
  if not u then
    return notify(err, vim.log.levels.ERROR)
  end
  vim.api.nvim_put({ format_link(ref, u) }, "c", true, true)
  if opts.open then
    open_ref(ref)
  end
end

--- Ask for a reference and insert its link at the cursor.
---@param opts? { open?: boolean }
function M.prompt(opts)
  vim.ui.input({ prompt = "Bible reference: " }, function(input)
    if input and input ~= "" then
      M.insert(input, opts)
    end
  end)
end

--- Normal mode: link the reference under the cursor, or prompt if there is none.
---@param opts? { open?: boolean }
function M.link_under_cursor(opts)
  opts = opts or {}
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_get_current_line()
  local m = parser.at(line, col + 1, M.config.languages)
  if not m then
    return M.prompt(opts)
  end
  if already_linked(line, m) then
    if opts.open then
      open_ref(m.ref)
    end
    return
  end
  local after = replace(row, m.s, m.e, m.ref)
  if after then
    vim.api.nvim_win_set_cursor(0, { row, math.max(after - 1, 0) })
    if opts.open then
      open_ref(m.ref)
    end
  end
end

--- Link the text between the '< and '> marks (single line).
---@param opts? { open?: boolean }
function M.link_selection(opts)
  opts = opts or {}
  local s, e = vim.fn.getpos("'<"), vim.fn.getpos("'>")
  if s[2] ~= e[2] then
    return notify("jw-linker: selection must be on a single line")
  end
  local row = s[2]
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, true)[1]
  local last = math.min(e[3], #line)
  last = last + vim.str_utf_end(line, last)
  local text = line:sub(s[3], last)
  local ref = parser.parse(text, M.config.languages)
  if not ref then
    return notify(("jw-linker: could not parse %q"):format(text))
  end
  -- keep surrounding whitespace of the selection out of the link
  local lead = #text:match("^%s*")
  local trail = #text:match("%s*$")
  local after = replace(row, s[3] + lead, last - trail, ref)
  if after then
    vim.api.nvim_win_set_cursor(0, { row, math.max(after - 1, 0) })
    if opts.open then
      open_ref(ref)
    end
  end
end

--- Open the markdown link or the plain reference under the cursor.
function M.open_under_cursor()
  local col = vim.api.nvim_win_get_cursor(0)[2] + 1
  local line = vim.api.nvim_get_current_line()
  for s, target, e in line:gmatch("()%[[^%]]*%]%(([^%)%s]+)%)()") do
    if s <= col and col < e then
      return M.open_url(target)
    end
  end
  local m = parser.at(line, col, M.config.languages)
  if not m then
    return notify("jw-linker: no link or reference under cursor")
  end
  open_ref(m.ref)
end

--- Entry point for :JWLink / :JWLinkOpen.
function M.command(cmd, open)
  local opts = { open = open }
  if cmd.args ~= "" then
    M.insert(cmd.args, opts)
  elseif cmd.range == 2 and vim.fn.getpos("'<")[2] == cmd.line1 then
    M.link_selection(opts)
  else
    M.link_under_cursor(opts)
  end
end

local function set_keymaps(buf)
  local km = M.config.keymaps
  if not km then
    return
  end
  local function map(mode, lhs, rhs, desc)
    if lhs then
      vim.keymap.set(mode, lhs, rhs, { buffer = buf, desc = desc, silent = true })
    end
  end
  map("i", km.insert_link, function()
    M.link_before_cursor()
  end, "JW: link reference")
  map("i", km.insert_link_open, function()
    M.link_before_cursor({ open = true })
  end, "JW: link reference and open")
  map("n", km.link, function()
    M.link_under_cursor()
  end, "JW: link reference")
  map("n", km.link_open, function()
    M.link_under_cursor({ open = true })
  end, "JW: link reference and open")
  map("x", km.link, ":JWLink<CR>", "JW: link selection")
  map("x", km.link_open, ":JWLinkOpen<CR>", "JW: link selection and open")
  map("n", km.open, M.open_under_cursor, "JW: open passage under cursor")
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  if opts and opts.languages then
    M.config.languages = opts.languages -- lists replace, not merge
  end
  if opts and opts.filetypes then
    M.config.filetypes = opts.filetypes
  end

  local group = vim.api.nvim_create_augroup("jw-linker", { clear = true })
  local fts = M.config.filetypes or {}
  if #fts == 0 then
    set_keymaps(nil)
    return
  end
  vim.api.nvim_create_autocmd("FileType", {
    group = group,
    pattern = fts,
    callback = function(ev)
      set_keymaps(ev.buf)
    end,
  })
  -- buffers that were already open before setup()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(buf) and vim.tbl_contains(fts, vim.bo[buf].filetype) then
      set_keymaps(buf)
    end
  end
end

return M
