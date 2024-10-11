local M = {}

-- Default colors
local default_colors = {
  todo = '#FF8C00',  -- Dark Orange
  fixme = '#FF0000', -- Red
  note = '#1E90FF',  -- Dodger Blue
}

-- Function to set highlights
local function set_highlights(colors)
  vim.api.nvim_set_hl(0, 'CommentTodo', { fg = colors.todo, bold = true })
  vim.api.nvim_set_hl(0, 'CommentFixme', { fg = colors.fixme, bold = true })
  vim.api.nvim_set_hl(0, 'CommentNote', { fg = colors.note, bold = true })
end

-- Table of comment patterns for different file types
local comment_patterns = {
  -- Single-line comment patterns
  single = {
    lua = '--',
    python = '#',
    sh = '#',
    ruby = '#',
    perl = '#',
    vim = '"',
    yaml = '#',
    toml = '#',
    ini = ';',
    sql = '--',
  },
  -- Multi-line comment patterns
  multi = {
    c = {'/*', '*/'},
    cpp = {'/*', '*/'},
    java = {'/*', '*/'},
    javascript = {'/*', '*/'},
    typescript = {'/*', '*/'},
    php = {'/*', '*/'},
    css = {'/*', '*/'},
    html = {'<!--', '-->'},
    xml = {'<!--', '-->'},
  }
}

-- Function to get the appropriate comment pattern for the current buffer
local function get_comment_pattern()
  local ft = vim.bo.filetype
  local single_pattern = comment_patterns.single[ft]
  local multi_pattern = comment_patterns.multi[ft]

  if single_pattern then
    return '^%s*' .. vim.pesc(single_pattern) .. '%s*'
  elseif multi_pattern then
    return '^%s*' .. vim.pesc(multi_pattern[1]) .. '.-' .. vim.pesc(multi_pattern[2])
  else
    -- Default to C-style comments for unknown file types
    return '^%s*[//#]-%s*'
  end
end

-- Function to highlight comments
local function highlight_comments()
  local bufnr = vim.api.nvim_get_current_buf()
  local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
  local comment_pattern = get_comment_pattern()
  
  -- Clear existing highlights
  vim.api.nvim_buf_clear_namespace(bufnr, -1, 0, -1)
  
  for i, line in ipairs(lines) do
    local start_col, end_col = line:find(comment_pattern)
    if start_col then
      local comment_text = line:sub(start_col)
      if comment_text:match('TODO') then
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'CommentTodo', i-1, start_col-1, -1)
      elseif comment_text:match('FIXME') then
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'CommentFixme', i-1, start_col-1, -1)
      elseif comment_text:match('NOTE') then
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'CommentNote', i-1, start_col-1, -1)
			elseif comment_text:match('*') then
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'CommentTodo', i-1, start_col-1, -1)
			elseif comment_text:match('!') then
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'CommentFixme', i-1, start_col-1, -1)
			elseif comment_text:match('?') then
        vim.api.nvim_buf_add_highlight(bufnr, -1, 'CommentNote', i-1, start_col-1, -1)
      end
    end
  end
end

-- Debounce function to limit the frequency of updates
local function debounce(func, timeout)
  local timer_id
  return function(...)
    if timer_id then
      vim.fn.timer_stop(timer_id)
    end
    local args = {...}
    timer_id = vim.fn.timer_start(timeout, function()
      func(unpack(args))
    end)
  end
end

-- Debounced version of highlight_comments
local highlight_comments_debounced = debounce(highlight_comments, 100)

-- Setup function
function M.setup()

	opts = opts or {}
  local colors = vim.tbl_deep_extend("force", default_colors, opts.colors or {})

  set_highlights(colors)
  
  -- Create an autocommand group
  local augroup = vim.api.nvim_create_augroup("CommentHighlighter", { clear = true })
  
  -- Trigger on entering a buffer, after writing, when changing file type, when exiting insert mode, and when opening a file
  vim.api.nvim_create_autocmd({"BufEnter", "BufWritePost", "FileType", "InsertLeave", "BufRead", "BufNewFile"}, {
    group = augroup,
    pattern = "*",
    callback = function()
      highlight_comments()
    end,
  })

  -- Trigger on every change in normal mode and insert mode
  vim.api.nvim_create_autocmd({"TextChanged", "TextChangedI"}, {
    group = augroup,
    pattern = "*",
    callback = function()
      highlight_comments_debounced()
    end,
  })
end

return M
