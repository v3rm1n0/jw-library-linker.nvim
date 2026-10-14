-- Run with: nvim --headless -u NONE -l tests/run.lua
vim.opt.rtp:prepend(vim.fn.getcwd())
vim.cmd.runtime("plugin/jw-linker.lua")

local parser = require("jw-linker.parser")
local url = require("jw-linker.url")
local jw = require("jw-linker")

local langs = { "de", "en" }
local failures, count = 0, 0

local function eq(name, got, want)
  count = count + 1
  if not vim.deep_equal(got, want) then
    failures = failures + 1
    print(("FAIL %s\n  got:  %s\n  want: %s"):format(name, vim.inspect(got), vim.inspect(want)))
  end
end

local function code(text)
  local ref = parser.parse(text, langs)
  return ref and url.bible_code(ref)
end

-- parsing / bible codes
eq("Joh 3:16", code("Joh 3:16"), "43003016")
eq("German comma", code("Joh 3,16"), "43003016")
eq("full German name", code("Johannes 3:16"), "43003016")
eq("numbered book with dot", code("1. Mose 1:1"), "01001001")
eq("numbered abbreviation", code("1Mo 1:1-3"), "01001001-01001003")
eq("umlaut abbreviation", code("1Kö 18:21"), "11018021")
eq("1Ko is Corinthians", code("1Ko 13:4"), "46013004")
eq("Römer", code("Röm 15:4"), "45015004")
eq("Matthäus prefix", code("Matth 24:14"), "40024014")
eq("English name", code("Revelation 21:4"), "66021004")
eq("English numbered", code("1 John 4:8"), "62004008")
eq("cross chapter", code("Mat 5:3-6:4"), "40005003-40006004")
eq("en dash", code("Ps 83:18–19"), "19083018-19083019")
eq("whole chapter", code("Ps 23"), "19023000-19023999")
eq("chapter range", code("Jes 2-3"), "23002000-23003999")
eq("single-chapter book", code("Jud 9"), "65001009")
eq("single-chapter range", code("Phm 10-12"), "57001010-57001012")
eq("Hohes Lied", code("Hohes Lied 8:6"), "22008006")
eq("ambiguous prefix", code("Jo 3:16"), nil)
eq("unknown book", code("Foo 3:16"), nil)
eq("reversed range", code("Joh 3:18-16"), nil)
eq("verse list rejected", code("Mat 24:14, 15"), nil)

-- scanning
local m = parser.ending_at("Wie in Joh 3:16", 15, langs)
eq("ending_at span", m and { m.s, m.e }, { 8, 15 })
m = parser.ending_at("lies 1. Mose 1:1", 16, langs)
eq("ending_at numbered", m and { m.s, m.e }, { 6, 16 })
m = parser.at("Siehe Mat 24:14 und so", 9, langs)
eq("at span", m and m.ref.label, "Mat 24:14")
m = parser.at("text (Ps 23:1) text", 8, langs)
eq("at inside parens", m and m.ref.label, "Ps 23:1")
eq("plain text", parser.at("nothing here 42", 3, langs), nil)

-- url templates
jw.setup({})
eq("jwlibrary url", jw.url("Joh 3:16"),
  "jwlibrary:///finder?srcid=jwlshare&wtlocale=X&prefer=lang&bible=43003016")
jw.setup({ locale = "E", pub = "nwtsty" })
eq("jworg url with pub", jw.url("John 3:16", "jworg"),
  "https://www.jw.org/finder?srcid=jwlshare&wtlocale=E&prefer=lang&bible=43003016&pub=nwtsty")
jw.setup({ target = "pergament" })
local u, err = jw.url("Joh 3:16")
eq("pergament unset", { u, err ~= nil }, { nil, true })
jw.setup({ target = "pergament", templates = { pergament = "pergament://{book}/{chapter}/{verse}?r={ref}" } })
eq("pergament template", jw.url("Joh 3:16"), "pergament://43/3/16?r=Joh%203%3A16")
jw.setup({ templates = { jwlibrary = function(ref) return "x:" .. ref.book end } })
eq("function template", jw.url("Joh 3:16"), "x:43")

-- buffer edits
jw.setup({})
local opened = {}
jw.open_url = function(target) table.insert(opened, target) end
local L = "jwlibrary:///finder?srcid=jwlshare&wtlocale=X&prefer=lang&bible="

vim.api.nvim_buf_set_lines(0, 0, -1, true, { "Siehe Joh 3:16 mehr" })
vim.api.nvim_win_set_cursor(0, { 1, 15 })
jw.link_before_cursor()
eq("insert-mode link", vim.api.nvim_get_current_line(), "Siehe [Joh 3:16](" .. L .. "43003016) mehr")
eq("insert-mode cursor keeps trailing space", vim.api.nvim_win_get_cursor(0)[2], #vim.api.nvim_get_current_line() - 4)
eq("insert-mode no open", #opened, 0)

vim.api.nvim_buf_set_lines(0, 0, -1, true, { "Lies Ps 23 heute" })
vim.api.nvim_win_set_cursor(0, { 1, 6 })
jw.link_under_cursor({ open = true })
eq("normal link", vim.api.nvim_get_current_line(), "Lies [Ps 23](" .. L .. "19023000-19023999) heute")
eq("normal link opens", opened, { L .. "19023000-19023999" })

opened = {}
vim.api.nvim_win_set_cursor(0, { 1, 7 })
jw.link_under_cursor({ open = true })
eq("already linked is not wrapped twice", vim.api.nvim_get_current_line(),
  "Lies [Ps 23](" .. L .. "19023000-19023999) heute")
eq("already linked still opens", #opened, 1)

opened = {}
jw.open_under_cursor()
eq("open link under cursor", opened, { L .. "19023000-19023999" })

vim.api.nvim_buf_set_lines(0, 0, -1, true, { "a Offenbarung 21:3, 4 b" })
vim.fn.setpos("'<", { 0, 1, 3, 0 })
vim.fn.setpos("'>", { 0, 1, 18, 0 })
jw.link_selection()
eq("visual link", vim.api.nvim_get_current_line(), "a [Offenbarung 21:3](" .. L .. "66021003), 4 b")

vim.api.nvim_buf_set_lines(0, 0, -1, true, { "" })
vim.api.nvim_win_set_cursor(0, { 1, 0 })
vim.cmd("JWLink 2. Tim 3:16, 17")
eq(":JWLink rejects lists", vim.api.nvim_get_current_line(), "")
vim.cmd("JWLink 2. Tim 3:16-17")
eq(":JWLink with args", vim.api.nvim_get_current_line(), "[2. Tim 3:16-17](" .. L .. "55003016-55003017)")

print(("%d/%d passed"):format(count - failures, count))
vim.cmd(failures == 0 and "qa!" or "cq")
