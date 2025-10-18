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
-- require("tenkai").register({
--   ft = { "cpp", "c" },
--   trigger = "if;",
--   snippet = [[
-- if (${1:condition}) {
--   $0
-- }
-- ]],
--   opts = {
--     head_only = true,  -- optional
--     tail_only = false, -- optional
--   },
-- })
--
-- -- opts なしでもOK
-- require("tenkai").register({
--   ft = "cpp",
--   trigger = "for;",
--   snippet = [[
-- for (${1:i} = 0; ${1:i} < ${2:n}; ++${1:i}) {
--   $0
-- }
-- ]],
-- })

local M = {}

-- Create a snippet trigger
--- @param opts table Configuration options for the snippet
--- @param opts.ft string|table The filetype(s) for which the snippet is active
--- @param opts.trigger string The trigger pattern that activates the snippet
--- @param opts.snippet string The snippet content to be inserted
--- @param opts.opts table|nil Optional configuration for snippet behavior
--- @param opts.opts.head_only boolean|nil If true, trigger only matches at word boundaries (start)
--- @param opts.opts.tail_only boolean|nil If true, trigger only matches at word boundaries (end)
--- @return nil
function M.register(opts)
  if not opts then
    error("tenkai.register: opts is required")
  end

  if not opts.trigger then
    error("tenkai.register: trigger pattern is required")
  end

  if not opts.snippet then
    error("tenkai.register: snippet content is required")
  end

  -- Use "*" as default filetype when ft is omitted
  local ft = opts.ft or "*"

  -- Get snippet options
  local snippet_opts = opts.opts or {}
  local head_only = snippet_opts.head_only
  local tail_only = snippet_opts.tail_only

  -- Get the last character of the trigger for early return optimization
  local trigger_last_char = opts.trigger:sub(-1)
  local trigger_length = #opts.trigger

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

      -- Early return if the cursor position is too short for the trigger
      if col < trigger_length then
        return
      end

      -- Early return if the last character doesn't match (only when no regex options are set)
      if not head_only and not tail_only and line:sub(col, col) ~= trigger_last_char then
        return
      end

      local before_cursor = line:sub(1, col)
      local match_found = false
      local match_start, match_end

      if head_only or tail_only then
        -- Use regex matching when boundary options are set
        local trigger_pattern = opts.trigger

        if head_only and tail_only then
          -- Match only if trigger is a complete word
          trigger_pattern = "\\<" .. vim.pesc(opts.trigger) .. "\\>"
        elseif head_only then
          -- Match only at word start
          trigger_pattern = "\\<" .. vim.pesc(opts.trigger)
        elseif tail_only then
          -- Match only at word end
          trigger_pattern = vim.pesc(opts.trigger) .. "\\>"
        end

        -- Find the last match in before_cursor
        local start_pos = 1
        while true do
          local s, e = vim.fn.matchstrpos(before_cursor, trigger_pattern, start_pos - 1)
          if s == "" then
            break
          end
          match_start = s
          match_end = e
          start_pos = e + 1
        end

        -- Check if the match ends exactly at cursor position
        if match_end and match_end == col then
          match_found = true
        end
      else
        -- Simple string matching when no boundary options are set
        if before_cursor:sub(-trigger_length) == opts.trigger then
          match_found = true
          match_start = col - trigger_length + 1
          match_end = col
        end
      end

      if match_found then
        vim.schedule(function()
          -- Remove the trigger text
          local new_line = line:sub(1, match_start - 1) .. line:sub(match_end + 1)
          vim.api.nvim_set_current_line(new_line)
          vim.api.nvim_win_set_cursor(0, { vim.api.nvim_win_get_cursor(0)[1], match_start - 1 })

          -- Expand the snippet
          vim.snippet.expand(opts.snippet)
        end)
      end
    end,
  })
end

return M
