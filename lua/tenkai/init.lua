local M = {}
local H = {}

-- # tenkai.nvim
--
-- ## feature
--
-- auto triger snippets
-- triger ;
-- target filettype: cpp
-- target word: ^for$
-- expands to:
-- for (int $1 = 0; $1 < $2; $1++) {
--   $0
-- }
-- autocmd("TextChangedI", {
--   pattern = "*",
--   group = vim.api.nvim_create_augroup("snippets_trigger", { clear = true }),
--   callback = function()
--     if vim.bo.filetype == "cpp" then
--       local line = vim.api.nvim_get_current_line()
--       local col = vim.api.nvim_win_get_cursor(0)[2]
--       local before_cursor = line:sub(1, col)
--       if before_cursor:match("%s*for;$") then
--         vim.schedule(function()
--           vim.api.nvim_set_current_line(line:sub(1, col - 4) .. line:sub(col + 1))
--           vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], col - 4 })
--           vim.snippet.expand("for (${1:int i = 0}; ${2:i < n}; ${3:++i}) {\n\t${0}\n}")
--         end)
--         return
--       end
--     end
--   end,
-- })
--
-- if use this plugin
--
-- local for_index =[[
-- for (${1:int i = 0}; ${2:i < n}; ${3:++i}) {
--   ${0}
-- }
-- ]]
-- require("tenkai").create({
--   ft = "cpp",
--   trigger = "^for;$",
--   snippets = for_index,
-- })

return M
