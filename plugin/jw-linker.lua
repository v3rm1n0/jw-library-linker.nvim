if vim.g.loaded_jw_linker then
  return
end
vim.g.loaded_jw_linker = true

vim.api.nvim_create_user_command("JWLink", function(cmd)
  require("jw-linker").command(cmd, false)
end, { nargs = "*", range = true, desc = "Insert a JW Library link for a Bible reference" })

vim.api.nvim_create_user_command("JWLinkOpen", function(cmd)
  require("jw-linker").command(cmd, true)
end, { nargs = "*", range = true, desc = "Insert a JW Library link and open the passage" })

vim.api.nvim_create_user_command("JWOpen", function(cmd)
  if cmd.args ~= "" then
    local url, err = require("jw-linker").url(cmd.args, require("jw-linker").config.open_target)
    if not url then
      return vim.notify(err, vim.log.levels.ERROR)
    end
    return require("jw-linker").open_url(url)
  end
  require("jw-linker").open_under_cursor()
end, { nargs = "*", desc = "Open the Bible passage/link under the cursor" })
