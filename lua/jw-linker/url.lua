local M = {}

--- JW "bible" parameter: BBCCCVVV or a BBCCCVVV-BBCCCVVV range.
--- Whole chapters span verse 000-999.
---@param ref JwRef
function M.bible_code(ref)
  local first = string.format("%02d%03d%03d", ref.book, ref.chapter, ref.verse or 0)
  local last = string.format("%02d%03d%03d", ref.book, ref.end_chapter, ref.end_verse or 999)
  if first == last then
    return first
  end
  return first .. "-" .. last
end

local function urlencode(s)
  return (s:gsub("[^%w%-%._~]", function(c)
    return string.format("%%%02X", c:byte())
  end))
end

---@param ref JwRef
---@param opts table plugin config
function M.vars(ref, opts)
  return {
    bible = M.bible_code(ref),
    book = ref.book,
    book2 = string.format("%02d", ref.book),
    chapter = ref.chapter,
    verse = ref.verse or 1,
    end_chapter = ref.end_chapter,
    end_verse = ref.end_verse or ref.verse or 1,
    locale = opts.locale,
    pub = opts.pub or "",
    pub_param = opts.pub and ("&pub=" .. opts.pub) or "",
    ref = urlencode(ref.label),
  }
end

--- Expand "{name}" placeholders.
function M.expand(template, vars)
  return (template:gsub("{([%w_]+)}", function(k)
    local v = vars[k]
    return v ~= nil and tostring(v) or nil
  end))
end

--- Build the URL for `ref` using the template registered for `target`.
---@return string|nil url, string|nil err
function M.build(ref, target, opts)
  local tpl = opts.templates[target]
  if tpl == nil then
    if target == "pergament" then
      return nil, "jw-linker: no Pergament URL configured, set `templates.pergament` in setup()"
    end
    return nil, ("jw-linker: unknown target %q (no entry in `templates`)"):format(target)
  end
  if type(tpl) == "function" then
    return tpl(ref, M.vars(ref, opts))
  end
  return M.expand(tpl, M.vars(ref, opts))
end

return M
