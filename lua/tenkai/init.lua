local M = {}

-- # tenkai.nvim
--
-- ## feature
--
-- auto triger snippet
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
--   trigger = "^%s*for;$",
--   snippet = for_index,
-- })

local M = {}

-- Create a snippet trigger
--- @param opts table Configuration options for the snippet
--- @param opts.trigger string The trigger pattern that activates the snippet
--- @param opts.snippet string The snippet content to be inserted
--- @return nil
function M.create(opts)
  if not opts then
    error("tenkai.create: opts is required")
  end

  if not opts.trigger then
    error("tenkai.create: trigger pattern is required")
  end

  if not opts.snippet then
    error("tenkai.create: snippet content is required")
  end

  -- Use "*" as default filetype when ft is omitted
  local ft = opts.ft or "*"

  -- Handle multiple filetypes
  local pattern
  if type(ft) == "table" then
    local patterns = {}
    for _, filetype in ipairs(ft) do
      table.insert(patterns, "*." .. filetype)
    end
    pattern = patterns
  elseif ft == "*" then
    pattern = "*"
  else
    pattern = "*." .. ft
  end

  -- Create autocommand for this specific trigger
  vim.api.nvim_create_autocmd("TextChangedI", {
    pattern = pattern,
    group = vim.api.nvim_create_augroup(
      "tenkai_" .. (type(ft) == "table" and table.concat(ft, "_") or ft) .. "_" .. opts.trigger:gsub("[^%w]", "_"),
      { clear = false }
    ),
    callback = function()
      local line = vim.api.nvim_get_current_line()
      local col = vim.api.nvim_win_get_cursor(0)[2]
      local before_cursor = line:sub(1, col)

      if before_cursor:match(opts.trigger) then
        vim.schedule(function()
          -- Remove the trigger text
          local match_start = before_cursor:find(opts.trigger:gsub("%^", ""):gsub("%$", ""))
          if match_start then
            local new_line = line:sub(1, match_start - 1) .. line:sub(col + 1)
            vim.api.nvim_set_current_line(new_line)
            vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], match_start - 1 })

            -- Expand the snippet
            vim.snippet.expand(opts.snippet)
          end
        end)
      end
    end,
  })
end

return M
