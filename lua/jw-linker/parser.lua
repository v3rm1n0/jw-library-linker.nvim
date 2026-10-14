local books = require("jw-linker.books")

local M = {}

---@class JwRef
---@field book integer
---@field chapter integer
---@field verse integer|nil      nil = whole chapter
---@field end_chapter integer
---@field end_verse integer|nil
---@field label string           the text as written

-- Tried in order; all anchored, "%s*[:,]%s*" accepts "3:16", "3,16" and "3, 16".
local SEP = "%s*[:,]%s*"
local DASH = "%s*%-%s*"
local patterns = {
  { "^(.-)%s*(%d+)" .. SEP .. "(%d+)" .. DASH .. "(%d+)" .. SEP .. "(%d+)$", "cv-cv" },
  { "^(.-)%s*(%d+)" .. SEP .. "(%d+)" .. DASH .. "(%d+)$", "cv-v" },
  { "^(.-)%s*(%d+)" .. SEP .. "(%d+)$", "cv" },
  { "^(.-)%s*(%d+)" .. DASH .. "(%d+)$", "c-c" },
  { "^(.-)%s*(%d+)$", "c" },
}

-- Optional leading book number, then letters (incl. UTF-8), dots and spaces.
local function looks_like_book(s)
  return s:match("^%d?%.?%s*[%a\128-\255][%a\128-\255%.%s]*$") ~= nil
end

--- Parse a scripture reference like "Joh 3:16", "1. Mose 1,1-3", "Mat 5:3-6:4", "Ps 23".
---@param text string
---@param languages string[]
---@return JwRef|nil
function M.parse(text, languages)
  local s = vim.trim(text):gsub("–", "-"):gsub("—", "-")
  for _, p in ipairs(patterns) do
    local caps = { s:match(p[1]) }
    if #caps > 0 then
      local name = vim.trim(caps[1])
      if not looks_like_book(name) then
        return nil
      end
      local num = books.lookup(name, languages)
      if not num then
        return nil
      end
      local n = vim.tbl_map(tonumber, { unpack(caps, 2) })
      local ref = { book = num, label = vim.trim(text) }
      local kind = p[2]
      if books.single_chapter[num] and (kind == "c" or kind == "c-c") then
        -- "Jud 3" / "Jud 3-5" are verses in a single-chapter book
        kind = kind == "c" and "cv" or "cv-v"
        table.insert(n, 1, 1)
      end
      if kind == "cv-cv" then
        ref.chapter, ref.verse, ref.end_chapter, ref.end_verse = n[1], n[2], n[3], n[4]
      elseif kind == "cv-v" then
        ref.chapter, ref.verse, ref.end_chapter, ref.end_verse = n[1], n[2], n[1], n[3]
      elseif kind == "cv" then
        ref.chapter, ref.verse, ref.end_chapter, ref.end_verse = n[1], n[2], n[1], n[2]
      elseif kind == "c-c" then
        ref.chapter, ref.end_chapter = n[1], n[2]
      else
        ref.chapter, ref.end_chapter = n[1], n[1]
      end
      if ref.chapter < 1 or ref.end_chapter < ref.chapter then
        return nil
      end
      if ref.verse and ref.end_chapter == ref.chapter and ref.end_verse < ref.verse then
        return nil
      end
      return ref
    end
  end
  return nil
end

--- Find all references in a line.
--- Spans start at a word start and end after a digit; 1-based, inclusive.
---@param line string
---@param languages string[]
---@return { s: integer, e: integer, ref: JwRef }[]
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
      if e > s and e - s < 48 then
        local ref = M.parse(line:sub(s, e), languages)
        if ref then
          table.insert(found, { s = s, e = e, ref = ref })
        end
      end
    end
  end
  return found
end

--- Longest reference containing byte column `col` (1-based).
function M.at(line, col, languages)
  local best
  for _, m in ipairs(M.scan(line, languages)) do
    if m.s <= col and col <= m.e and (not best or m.e - m.s > best.e - best.s) then
      best = m
    end
  end
  return best
end

--- Longest reference ending exactly at byte column `col` (1-based).
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
