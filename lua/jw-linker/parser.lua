local books = require("jw-linker.books")

local M = {}

---@class JwRef
---@field book integer
---@field chapter integer
---@field verse integer|nil      nil = whole chapter
---@field end_chapter integer
---@field end_verse integer|nil
---@field label string           the text as written

---@class JwCitation
---@field refs JwRef[]
---@field pieces { text: string, ref?: JwRef }[]  linked parts and the separators between them

local DASH = "%s*%-%s*"

-- Optional leading book number, then letters (incl. UTF-8), dots and spaces.
local function looks_like_book(s)
  return s:match("^%d?%.?%s*[%a\128-\255][%a\128-\255%.%s]*$") ~= nil
end

-- Item forms, longest first. `CV` is the chapter/verse separator.
-- An item either starts a chapter ("cv" forms) or continues the current one.
local function chapter_forms(CV)
  return {
    { "(%d+)" .. CV .. "(%d+)" .. DASH .. "(%d+)" .. CV .. "(%d+)", "cv-cv" },
    { "(%d+)" .. CV .. "(%d+)" .. DASH .. "(%d+)", "cv-v" },
    { "(%d+)" .. CV .. "(%d+)", "cv" },
    { "(%d+)" .. DASH .. "(%d+)", "c-c" },
    { "(%d+)", "c" },
  }
end

local function verse_forms(CV)
  return {
    { "(%d+)" .. CV .. "(%d+)" .. DASH .. "(%d+)" .. CV .. "(%d+)", "cv-cv" },
    { "(%d+)" .. CV .. "(%d+)" .. DASH .. "(%d+)", "cv-v" },
    { "(%d+)" .. CV .. "(%d+)", "cv" },
    { "(%d+)" .. DASH .. "(%d+)" .. CV .. "(%d+)", "v-cv" },
    { "(%d+)" .. DASH .. "(%d+)", "v-v" },
    { "(%d+)", "v" },
  }
end

local function make_ref(book, chapter, kind, n)
  local r = { book = book }
  if kind == "cv-cv" then
    r.chapter, r.verse, r.end_chapter, r.end_verse = n[1], n[2], n[3], n[4]
  elseif kind == "cv-v" then
    r.chapter, r.verse, r.end_chapter, r.end_verse = n[1], n[2], n[1], n[3]
  elseif kind == "cv" then
    r.chapter, r.verse, r.end_chapter, r.end_verse = n[1], n[2], n[1], n[2]
  elseif kind == "c-c" then
    r.chapter, r.end_chapter = n[1], n[2]
  elseif kind == "c" then
    r.chapter, r.end_chapter = n[1], n[1]
  elseif kind == "v-cv" then
    r.chapter, r.verse, r.end_chapter, r.end_verse = chapter, n[1], n[2], n[3]
  elseif kind == "v-v" then
    r.chapter, r.verse, r.end_chapter, r.end_verse = chapter, n[1], chapter, n[2]
  else -- "v"
    r.chapter, r.verse, r.end_chapter, r.end_verse = chapter, n[1], chapter, n[1]
  end
  if not r.chapter or r.chapter < 1 or r.end_chapter < r.chapter then
    return nil
  end
  if r.verse and r.end_chapter == r.chapter and r.end_verse < r.verse then
    return nil
  end
  return r
end

--- Parse a citation such as "Joh 3:16", "1. Mose 1,1-3", "Mat 5:3-6:4", "Ps 23",
--- "1. Ko 8:4, 7", "Mat 5:3; 6:9" or "Joh 3,16.18".
---@param text string
---@param languages string[]
---@return JwCitation|nil
function M.parse(text, languages)
  text = vim.trim(text)
  -- same byte length, so offsets still point into `text`
  local s = text:gsub("–", "-  "):gsub("—", "-  ")

  local name, p = s:match("^(.-[%a\128-\255]%.?)%s*()%d")
  if not name or not looks_like_book(name) then
    return nil
  end
  local book = books.lookup(name, languages)
  if not book then
    return nil
  end

  -- "Joh 3:16, 18" lists with commas; without a colon the comma separates
  -- chapter and verse ("Joh 3,16") and lists use dots ("Joh 3,16.18").
  local colon = s:find(":", p, true) ~= nil
  local single = books.single_chapter[book] and not colon
  local CV = (colon or single) and "%s*:%s*" or "%s*,%s*"
  local LIST = (colon and "%s*,%s*") or (single and "%s*[,%.]%s*") or "%s*%.%s*"
  local CHAPTER = "%s*;%s*"

  local cit = { refs = {}, pieces = {} }
  local q, chapter = p, single and 1 or nil
  local forms = single and verse_forms(CV) or chapter_forms(CV)
  while true do
    local ref, item_start = nil, q
    for _, f in ipairs(forms) do
      local res = { s:find("^" .. f[1], q) }
      if res[1] then
        ref = make_ref(book, chapter, f[2], vim.tbl_map(tonumber, { unpack(res, 3) }))
        q = res[2] + 1
        break
      end
    end
    if not ref then
      return nil
    end
    chapter = ref.end_chapter
    local label_start = #cit.refs == 0 and 1 or item_start
    ref.label = text:sub(label_start, q - 1)
    table.insert(cit.refs, ref)
    table.insert(cit.pieces, { text = ref.label, ref = ref })

    if q > #s then
      return cit
    end
    local sep_end
    sep_end = select(2, s:find("^" .. CHAPTER, q))
    if sep_end then
      forms = chapter_forms(CV)
    else
      sep_end = select(2, s:find("^" .. LIST, q))
      if not sep_end then
        return nil
      end
      forms = verse_forms(CV)
    end
    table.insert(cit.pieces, { text = text:sub(q, sep_end) })
    q = sep_end + 1
  end
end

--- Find all citations in a line.
--- Spans start at a word start and end after a digit; 1-based, inclusive.
---@param line string
---@param languages string[]
---@return { s: integer, e: integer, cit: JwCitation }[]
function M.scan(line, languages)
  local starts, ends = {}, {}
  for i = 1, #line do
    local c, prev = line:sub(i, i), line:sub(i - 1, i - 1)
    if c:match("[%w\128-\255]") and (i == 1 or prev:match("[%s%(%[{\"'„“]")) then
      -- don't start inside a UTF-8 sequence
      if not c:match("[\128-\191]") then
        table.insert(starts, i)
      end
    end
    if c:match("%d") and not line:sub(i + 1, i + 1):match("%d") then
      table.insert(ends, i)
    end
  end
  local found = {}
  for _, s in ipairs(starts) do
    for _, e in ipairs(ends) do
      if e > s and e - s < 96 then
        local text = line:sub(s, e)
        -- "Joh 3:16, 1. Ko 8:4": the trailing "1" starts the next book
        local next_book = text:match("[,;]%s*[1-5]$") and line:sub(e + 1):match("^%.?%s*[%a\128-\255]")
        local cit = not next_book and M.parse(text, languages)
        if cit then
          table.insert(found, { s = s, e = e, cit = cit })
        end
      end
    end
  end
  return found
end

--- Longest citation containing byte column `col` (1-based).
function M.at(line, col, languages)
  local best
  for _, m in ipairs(M.scan(line, languages)) do
    if m.s <= col and col <= m.e and (not best or m.e - m.s > best.e - best.s) then
      best = m
    end
  end
  return best
end

--- Longest citation ending exactly at byte column `col` (1-based).
function M.ending_at(line, col, languages)
  local best
  for _, m in ipairs(M.scan(line:sub(1, col), languages)) do
    if m.e == col and (not best or m.s < best.s) then
      best = m
    end
  end
  return best
end

return M
