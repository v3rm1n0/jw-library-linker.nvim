-- Bible books in canonical order (index == JW book number).
-- Each language lists full names first, then common abbreviations
-- (NWT abbreviations plus a few widespread alternatives).
local M = {}

M.books = {
  { de = { "1. Mose", "1Mo", "1Mos", "Gen", "Genesis" }, en = { "Genesis", "Ge", "Gen" } },
  { de = { "2. Mose", "2Mo", "2Mos", "Exodus" }, en = { "Exodus", "Ex", "Exod" } },
  { de = { "3. Mose", "3Mo", "3Mos", "Levitikus" }, en = { "Leviticus", "Le", "Lev" } },
  { de = { "4. Mose", "4Mo", "4Mos", "Numeri" }, en = { "Numbers", "Nu", "Num" } },
  { de = { "5. Mose", "5Mo", "5Mos", "Deuteronomium" }, en = { "Deuteronomy", "De", "Deut" } },
  { de = { "Josua", "Jos" }, en = { "Joshua", "Jos", "Josh" } },
  { de = { "Richter", "Ri" }, en = { "Judges", "Jg", "Judg" } },
  { de = { "Ruth", "Rut" }, en = { "Ruth", "Ru" } },
  { de = { "1. Samuel", "1Sa", "1Sam" }, en = { "1 Samuel", "1Sa", "1Sam" } },
  { de = { "2. Samuel", "2Sa", "2Sam" }, en = { "2 Samuel", "2Sa", "2Sam" } },
  { de = { "1. Könige", "1Kö", "1Kön" }, en = { "1 Kings", "1Ki", "1Kgs" } },
  { de = { "2. Könige", "2Kö", "2Kön" }, en = { "2 Kings", "2Ki", "2Kgs" } },
  { de = { "1. Chronika", "1Ch", "1Chr" }, en = { "1 Chronicles", "1Ch", "1Chr" } },
  { de = { "2. Chronika", "2Ch", "2Chr" }, en = { "2 Chronicles", "2Ch", "2Chr" } },
  { de = { "Esra", "Esr" }, en = { "Ezra", "Ezr" } },
  { de = { "Nehemia", "Ne", "Neh" }, en = { "Nehemiah", "Ne", "Neh" } },
  { de = { "Esther", "Est" }, en = { "Esther", "Es", "Esth" } },
  { de = { "Hiob", "Hi" }, en = { "Job" } },
  { de = { "Psalm", "Psalmen", "Ps" }, en = { "Psalms", "Psalm", "Ps", "Psa" } },
  { de = { "Sprüche", "Spr" }, en = { "Proverbs", "Pr", "Prov" } },
  { de = { "Prediger", "Pred", "Kohelet" }, en = { "Ecclesiastes", "Ec", "Eccl" } },
  { de = { "Hohes Lied", "Hoheslied", "Hoh", "Hld" }, en = { "Song of Solomon", "Song of Songs", "Ca", "Song" } },
  { de = { "Jesaja", "Jes" }, en = { "Isaiah", "Isa" } },
  { de = { "Jeremia", "Jer" }, en = { "Jeremiah", "Jer" } },
  { de = { "Klagelieder", "Klg", "Klgl" }, en = { "Lamentations", "La", "Lam" } },
  { de = { "Hesekiel", "Hes", "Ezechiel" }, en = { "Ezekiel", "Eze", "Ezek" } },
  { de = { "Daniel", "Da", "Dan" }, en = { "Daniel", "Da", "Dan" } },
  { de = { "Hosea", "Hos" }, en = { "Hosea", "Ho", "Hos" } },
  { de = { "Joel" }, en = { "Joel", "Joe" } },
  { de = { "Amos", "Am" }, en = { "Amos", "Am" } },
  { de = { "Obadja", "Ob", "Obd" }, en = { "Obadiah", "Ob", "Obad" } },
  { de = { "Jona", "Jon" }, en = { "Jonah", "Jon" } },
  { de = { "Micha", "Mi" }, en = { "Micah", "Mic" } },
  { de = { "Nahum", "Nah" }, en = { "Nahum", "Na", "Nah" } },
  { de = { "Habakuk", "Hab" }, en = { "Habakkuk", "Hab" } },
  { de = { "Zephanja", "Ze", "Zef" }, en = { "Zephaniah", "Zep", "Zeph" } },
  { de = { "Haggai", "Hag" }, en = { "Haggai", "Hag" } },
  { de = { "Sacharja", "Sach" }, en = { "Zechariah", "Zec", "Zech" } },
  { de = { "Maleachi", "Mal" }, en = { "Malachi", "Mal" } },
  { de = { "Matthäus", "Mat", "Mt" }, en = { "Matthew", "Mt", "Matt" } },
  { de = { "Markus", "Mar", "Mk" }, en = { "Mark", "Mr", "Mk" } },
  { de = { "Lukas", "Luk", "Lk" }, en = { "Luke", "Lu", "Lk" } },
  { de = { "Johannes", "Joh" }, en = { "John", "Joh", "Jn" } },
  { de = { "Apostelgeschichte", "Apg" }, en = { "Acts", "Ac" } },
  { de = { "Römer", "Rö", "Röm" }, en = { "Romans", "Ro", "Rom" } },
  { de = { "1. Korinther", "1Ko", "1Kor" }, en = { "1 Corinthians", "1Co", "1Cor" } },
  { de = { "2. Korinther", "2Ko", "2Kor" }, en = { "2 Corinthians", "2Co", "2Cor" } },
  { de = { "Galater", "Gal" }, en = { "Galatians", "Ga", "Gal" } },
  { de = { "Epheser", "Eph" }, en = { "Ephesians", "Eph" } },
  { de = { "Philipper", "Php", "Phil" }, en = { "Philippians", "Php", "Phil" } },
  { de = { "Kolosser", "Kol" }, en = { "Colossians", "Col" } },
  { de = { "1. Thessalonicher", "1Th", "1Thess" }, en = { "1 Thessalonians", "1Th", "1Thess" } },
  { de = { "2. Thessalonicher", "2Th", "2Thess" }, en = { "2 Thessalonians", "2Th", "2Thess" } },
  { de = { "1. Timotheus", "1Ti", "1Tim" }, en = { "1 Timothy", "1Ti", "1Tim" } },
  { de = { "2. Timotheus", "2Ti", "2Tim" }, en = { "2 Timothy", "2Ti", "2Tim" } },
  { de = { "Titus", "Tit" }, en = { "Titus", "Tit" } },
  { de = { "Philemon", "Phm", "Phlm" }, en = { "Philemon", "Phm", "Philem" } },
  { de = { "Hebräer", "Heb", "Hebr" }, en = { "Hebrews", "Heb" } },
  { de = { "Jakobus", "Jak" }, en = { "James", "Jas" } },
  { de = { "1. Petrus", "1Pe", "1Petr" }, en = { "1 Peter", "1Pe", "1Pet" } },
  { de = { "2. Petrus", "2Pe", "2Petr" }, en = { "2 Peter", "2Pe", "2Pet" } },
  { de = { "1. Johannes", "1Jo", "1Joh" }, en = { "1 John", "1Jo", "1Jn" } },
  { de = { "2. Johannes", "2Jo", "2Joh" }, en = { "2 John", "2Jo", "2Jn" } },
  { de = { "3. Johannes", "3Jo", "3Joh" }, en = { "3 John", "3Jo", "3Jn" } },
  { de = { "Judas", "Jud" }, en = { "Jude" } },
  { de = { "Offenbarung", "Off", "Offb" }, en = { "Revelation", "Re", "Rev" } },
}

-- Books with a single chapter: "Jud 3" means verse 3, not chapter 3.
M.single_chapter = { [31] = true, [57] = true, [63] = true, [64] = true, [65] = true }

local umlauts = { ["ä"] = "ae", ["ö"] = "oe", ["ü"] = "ue", ["ß"] = "ss" }

--- Normalize a book name for lookup: lowercase, umlauts expanded,
--- spaces and dots removed ("1. Könige" -> "1koenige").
function M.normalize(name)
  local s = vim.fn.tolower(name)
  for from, to in pairs(umlauts) do
    s = s:gsub(from, to)
  end
  return (s:gsub("[%s%.]", ""))
end

local cache = {}

local function index_for(languages)
  local key = table.concat(languages, ",")
  if cache[key] then
    return cache[key]
  end
  local exact, entries = {}, {}
  -- Earlier languages win on alias collisions (e.g. "Pr").
  for _, lang in ipairs(languages) do
    for num, book in ipairs(M.books) do
      for _, alias in ipairs(book[lang] or {}) do
        local norm = M.normalize(alias)
        if exact[norm] == nil then
          exact[norm] = num
        end
        table.insert(entries, { norm = norm, num = num })
      end
    end
  end
  cache[key] = { exact = exact, entries = entries }
  return cache[key]
end

--- Resolve a book name to its number, or nil if unknown/ambiguous.
---@param name string
---@param languages string[]
---@return integer|nil
function M.lookup(name, languages)
  local norm = M.normalize(name)
  if #norm < 2 then
    return nil
  end
  local idx = index_for(languages)
  if idx.exact[norm] then
    return idx.exact[norm]
  end
  local found
  for _, entry in ipairs(idx.entries) do
    if entry.norm:sub(1, #norm) == norm then
      if found and found ~= entry.num then
        return nil -- ambiguous prefix
      end
      found = entry.num
    end
  end
  return found
end

return M
