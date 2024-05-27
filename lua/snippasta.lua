local M = {}
local api = vim.api


---@class snippasta.paste.Opts
---@field querytext string? treesitter query to use.
--- By default it uses queries from `tabstop.scm` in the runtime path.


---@param reg string? register to use. Defaults to v:register
---@param opts snippasta.paste.Opts?
function M.paste(reg, opts)
  opts = opts or {}
  local source = vim.fn.getreg(reg or "")
  local regtype = vim.fn.getregtype(reg or "")
  local mode = api.nvim_get_mode()

  local lines = vim.split(source, "\n", { plain = true })
  if regtype == "v" then
    -- Strips indentation of subsequent lines.
    -- Selection in normal visual mode is often like this:
    --
    --   ┌── selection start
    --   ▼
    --   first line is intended
    --   second line
    --   third line
    --▲
    --└──── indentation in subsequent lines is part of selection
    --      but undesired for snippet
    local indent = math.huge
    for i, line in ipairs(lines) do
      if i > 1 then
        indent = math.min(line:find("[^ ]") or math.huge, indent)
      end
    end
    indent = indent == math.huge and 0 or indent
    if indent > 0 then
      for i, line in ipairs(lines) do
        if i > 1 then
          lines[i] = line:sub(indent)
        end
      end
    end
    source = table.concat(lines, "\n")
  end

  local parser = vim.treesitter.get_string_parser(source, vim.bo.filetype)
  local trees = parser:parse()
  local root = trees[1]:root()
  if not root then
    return
  end
  local query = (
    opts.querytext
    and vim.treesitter.query.parse(parser:lang(), opts.querytext)
    or vim.treesitter.query.get(parser:lang(), "tabstop")
  )
  assert(query, "Must have a tabstop query file")

  ---@type table<integer, TSNode>
  local leafs = {}
  local nodes = {}
  for id, node, _, _ in query:iter_captures(root, source) do
    if query.captures[id] == "tabstop" then
      leafs[node:id()] = node
      table.insert(nodes, node)
    end
  end

  --- Prune any non-leafs; nested snippet placeholders are not supported
  for _, node in pairs(leafs) do
    local parent = node:parent()
    while parent ~= nil do
      leafs[parent:id()] = nil
      parent = parent:parent()
    end
  end

  local function is_leaf(n)
    return leafs[n:id()] ~= nil
  end

  for i, n in vim.iter(nodes):rev():filter(is_leaf):enumerate() do
    local slnum, scol, elnum, ecol = n:range()
    if slnum == elnum then
      local lnum = slnum + 1
      local line = lines[lnum]
      local text = line:sub(scol + 1, ecol):gsub("[%$%}]", "\\%1")
      lines[lnum] = table.concat({
        line:sub(1, scol),
        string.format("${%s:%s}", i, text),
        line:sub(ecol + 1)
      })
    end
  end
  -- this should kinda emulate a `yy` + `p` where the paste happens in the next line
  if mode.mode == "n" and regtype == "V" then
    if lines[#lines] == "" then
      table.remove(lines)
    end
    vim.cmd.normal("o")
  end
  local snippet = table.concat(lines, "\n")
  vim.snippet.expand(snippet)
end

return M
