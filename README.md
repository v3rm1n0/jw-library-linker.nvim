# jw-library-linker.nvim

Turn Bible references in your Markdown notes (zk, obsidian.nvim, plain `.md`) into
JW Library links – or links for any other app such as Pergament – and optionally
open the passage right away.

```
Joh 3:16▌   --<C-g>l-->   [Joh 3:16](jwlibrary:///finder?…&bible=43003016)▌
```

## Features

- Recognises German and English book names and abbreviations
  (`Joh 3:16`, `Joh 3,16`, `1. Mose 1:1-3`, `1Kö 18:21`, `Mat 5:3-6:4`, `Ps 23`, `Jud 9`, `Revelation 21:4`)
- Insert mode: link the reference you just typed, with or without opening it
- Normal/visual mode: link the reference under the cursor or the selection
- Open the link or plain reference under the cursor
- Targets: JW Library app, Pergament, jw.org, wol.jw.org, or your own URL template

## Installation

lazy.nvim:

```lua
{
  "v3rm1n0/jw-library-linker.nvim",
  ft = "markdown",
  cmd = { "JWLink", "JWLinkOpen", "JWOpen" },
  opts = {},
}
```

## Usage

| Mode   | Default key  | Command         | Action                                          |
| ------ | ------------ | --------------- | ----------------------------------------------- |
| insert | `<C-g>l`     |                 | link the reference before the cursor            |
| insert | `<C-g>o`     |                 | link it **and** open the passage                |
| normal | `<leader>jl` | `:JWLink`       | link the reference under the cursor (or prompt) |
| normal | `<leader>jo` | `:JWLinkOpen`   | link and open                                   |
| visual | `<leader>jl` | `:'<,'>JWLink`  | link the selection                              |
| visual | `<leader>jo` | `:'<,'>JWLinkOpen` | link the selection and open                  |
| normal | `<leader>jg` | `:JWOpen`       | open the link/reference under the cursor        |

`:JWLink Joh 3:16` and `:JWLinkOpen Joh 3:16` insert a link for the given reference
at the cursor. `:JWOpen Joh 3:16` only opens it.

A reference that is already the label of a Markdown link is not linked a second time.

## Configuration

Defaults:

```lua
require("jw-linker").setup({
  target = "jwlibrary",   -- template used for inserted links
  open_target = nil,      -- template used for opening; nil = same as target
  locale = "X",           -- wtlocale: "X" German, "E" English, ...
  pub = nil,              -- e.g. "nwtsty" for the study edition
  languages = { "de", "en" }, -- book names to recognise, first wins on collisions
  templates = {
    jwlibrary = "jwlibrary:///finder?srcid=jwlshare&wtlocale={locale}&prefer=lang&bible={bible}{pub_param}",
    jworg = "https://www.jw.org/finder?srcid=jwlshare&wtlocale={locale}&prefer=lang&bible={bible}{pub_param}",
    wol = "https://wol.jw.org/finder?wtlocale={locale}&bible={bible}{pub_param}",
    pergament = <built-in function>,
  },
  link_format = "[{label}]({url})", -- or function(label, url, ref)
  open_cmd = nil,         -- e.g. { "xdg-open" }; nil = vim.ui.open()
  filetypes = { "markdown" }, -- buffer-local keymaps; {} = global keymaps
  keymaps = {
    insert_link = "<C-g>l",
    insert_link_open = "<C-g>o",
    link = "<leader>jl",
    link_open = "<leader>jo",
    open = "<leader>jg",
  },
})
```

Set any keymap to `false` to disable it.

### Pergament

[Pergament](https://github.com/v3rm1n0/pergament) is a built-in target and gets
`pergament://bible/B:C:V-B:C:V` links (`pergament://bible/B:C` for whole chapters):

```lua
require("jw-linker").setup({ target = "pergament" })
```

### Custom templates

Template placeholders:

| Placeholder     | Example (`Joh 3:16-18`) |
| --------------- | ----------------------- |
| `{bible}`       | `43003016-43003018`     |
| `{book}`        | `43`                    |
| `{book2}`       | `43` (zero-padded)      |
| `{chapter}`     | `3`                     |
| `{verse}`       | `16`                    |
| `{end_chapter}` | `3`                     |
| `{end_verse}`   | `18`                    |
| `{locale}`      | `X`                     |
| `{pub}`         | `nwtsty` or empty       |
| `{pub_param}`   | `&pub=nwtsty` or empty  |
| `{ref}`         | `Joh%203%3A16-18`       |

A template can also be a function `function(ref, vars) return url end`.

Mixing targets works too, e.g. insert JW Library links (which also open on your
phone) but open passages on desktop in the browser:

```lua
require("jw-linker").setup({ target = "jwlibrary", open_target = "jworg" })
```

## Tests

```sh
nvim --headless -u NONE -l tests/run.lua
```

## License

MIT
