-- Small Neovim setup. Start with `:Tutor` to learn Vim motions.
vim.g.mapleader = ' '
vim.g.maplocalleader = '\\'

local opt = vim.opt
opt.number = true
opt.relativenumber = true
opt.signcolumn = 'yes'
opt.scrolloff = 5
opt.sidescrolloff = 5
opt.splitright = true
opt.splitbelow = true
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.undofile = true
opt.mouse = ''
opt.confirm = true
opt.hidden = true
opt.termguicolors = true
opt.background = 'light'
opt.completeopt = { 'menuone', 'noselect', 'popup' }
opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.updatetime = 300

vim.cmd.colorscheme('morning')

-- Make the vendored modules available while init.lua is being evaluated.
local mini_path = vim.fn.stdpath('data') .. '/site/pack/vendor/start/mini.nvim'
vim.opt.runtimepath:prepend(mini_path)

local root_markers = { '.git', 'Cargo.toml', 'go.work', 'go.mod', 'package.json', 'pyproject.toml' }
local function project_root()
  local name = vim.api.nvim_buf_get_name(0)
  return vim.fs.root(name ~= '' and name or vim.uv.cwd(), root_markers) or vim.uv.cwd()
end

local map = vim.keymap.set
map('n', '<Esc>', '<cmd>nohlsearch<cr>', { desc = 'Clear search highlight' })
map('n', '<leader>e', function()
  local name = vim.api.nvim_buf_get_name(0)
  require('mini.files').open(name ~= '' and name or vim.uv.cwd(), true)
end, { desc = 'Browse files' })
local function find_files()
  require('mini.pick').builtin.files(nil, { source = { cwd = project_root() } })
end
local function grep_project()
  require('mini.pick').builtin.grep_live(nil, { source = { cwd = project_root() } })
end
map('n', '<leader>ff', find_files, { desc = 'Find files in project' })
map('n', '<leader><space>', find_files, { desc = 'Find files in project' })
map('n', '<leader>sg', grep_project, { desc = 'Search project text' })
map('n', '<leader>/', grep_project, { desc = 'Search project text' })
map('n', '<leader>fb', function() require('mini.pick').builtin.buffers() end, { desc = 'Find buffer' })
map('n', '<leader>sh', function() require('mini.pick').builtin.help() end, { desc = 'Find help' })

require('mini.pick').setup()
require('mini.files').setup()
require('mini.statusline').setup()
require('mini.completion').setup({ delay = { completion = 250, info = 250, signature = 150 } })
local clue = require('mini.clue')
clue.setup({
  triggers = {
    { mode = { 'n', 'x' }, keys = '<Leader>' },
    { mode = 'n', keys = '<C-w>' },
    { mode = 'i', keys = '<C-x>' },
    { mode = { 'n', 'x' }, keys = 'g' },
    { mode = { 'n', 'x' }, keys = 'z' },
  },
  clues = {
    { mode = 'n', keys = '<Leader>f', desc = 'files' },
    { mode = 'n', keys = '<Leader>s', desc = 'search' },
    { mode = 'n', keys = '<Leader>c', desc = 'code' },
    { mode = 'n', keys = '<Leader>t', desc = 'tests' },
    clue.gen_clues.builtin_completion(),
    clue.gen_clues.g(),
    clue.gen_clues.windows(),
    clue.gen_clues.z(),
  },
})

vim.api.nvim_create_user_command('Keys', function()
  local path = vim.fn.stdpath('config') .. '/CHEATSHEET.md'
  vim.cmd('tabnew ' .. vim.fn.fnameescape(path))
end, { desc = 'Open the Chinese key cheatsheet' })

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'html', 'css' },
  callback = function()
    vim.bo.shiftwidth = 2
    vim.bo.softtabstop = 2
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'go',
  callback = function()
    vim.bo.expandtab = false
    vim.bo.shiftwidth = 4
    vim.bo.softtabstop = 4
  end,
})
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'markdown', 'text' },
  callback = function() vim.wo.wrap = true end,
})

vim.api.nvim_create_user_command('Root', function()
  local root = project_root()
  vim.cmd('cd ' .. vim.fn.fnameescape(root))
  vim.notify('Project root: ' .. root)
end, { desc = 'Change directory to nearest project root' })

local terminal_buf
local function toggle_terminal()
  if terminal_buf and vim.api.nvim_buf_is_valid(terminal_buf) then
    for _, win in ipairs(vim.fn.win_findbuf(terminal_buf)) do
      if vim.api.nvim_win_is_valid(win) then
        if #vim.api.nvim_tabpage_list_wins(0) > 1 then
          vim.api.nvim_win_close(win, true)
        end
        return
      end
    end
    local job = vim.b[terminal_buf].terminal_job_id
    if job and vim.fn.jobwait({ job }, 0)[1] == -1 then
      vim.cmd('botright 12split')
      vim.api.nvim_win_set_buf(0, terminal_buf)
      vim.cmd('startinsert')
      return
    end
  end
  local root = project_root()
  vim.cmd('botright 12split')
  vim.cmd('enew')
  terminal_buf = vim.api.nvim_get_current_buf()
  vim.fn.termopen(vim.o.shell, { cwd = root })
  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('ToggleTerm', toggle_terminal, { desc = 'Toggle project terminal' })
map('n', '<leader>ft', toggle_terminal, { desc = 'Project terminal' })
map('n', '<C-/>', toggle_terminal, { desc = 'Project terminal' })
map('t', '<C-/>', '<C-\\><C-n><cmd>ToggleTerm<cr>', { desc = 'Hide project terminal' })

local function list_bookmarks()
  local items = {}
  local function collect(marks, current_file)
    for _, mark in ipairs(marks) do
      local letter = mark.mark:match("^'([a-zA-Z])$")
      local pos = mark.pos
      local path = mark.file or current_file
      if letter and path and path ~= '' and pos and pos[2] > 0 then
        items[#items + 1] = {
          text = letter .. '  ' .. vim.fn.fnamemodify(path, ':~:.') .. ':' .. pos[2],
          path = path,
          lnum = pos[2],
          col = math.max(pos[3], 1),
        }
      end
    end
  end
  collect(vim.fn.getmarklist(), nil)
  collect(vim.fn.getmarklist(0), vim.api.nvim_buf_get_name(0))
  table.sort(items, function(a, b) return a.text < b.text end)
  if #items == 0 then
    vim.notify('No bookmarks yet. Press mA to set one, then `A to jump back.')
    return
  end
  require('mini.pick').start({ source = { items = items, name = 'Bookmarks' } })
end

vim.api.nvim_create_user_command('Bookmarks', list_bookmarks, { desc = 'Pick a Vim mark' })
map('n', '<leader>sm', list_bookmarks, { desc = 'Search marks' })

local function format_buffer()
  local ft = vim.bo.filetype
  local filename = vim.api.nvim_buf_get_name(0)
  local root = project_root()
  local cmd
  if ft == 'rust' and vim.fn.executable('rustfmt') == 1 then
    cmd = { 'rustfmt', '--emit', 'stdout' }
  elseif ft == 'go' and vim.fn.executable('gofmt') == 1 then
    cmd = { 'gofmt' }
  elseif ft == 'python' and vim.fn.executable('ruff') == 1 then
    cmd = { 'ruff', 'format', '--stdin-filename', filename ~= '' and filename or 'buffer.py', '-' }
  elseif ft == 'python' and vim.fn.executable('black') == 1 then
    cmd = { 'black', '--quiet', '-' }
  elseif vim.tbl_contains({ 'javascript', 'javascriptreact', 'typescript', 'typescriptreact', 'json', 'html', 'css' }, ft) then
    local local_prettier = root .. '/node_modules/.bin/prettier'
    local prettier = vim.fn.executable(local_prettier) == 1 and local_prettier or 'prettier'
    if vim.fn.executable(prettier) == 1 and filename ~= '' then
      cmd = { prettier, '--stdin-filepath', filename }
    end
  end

  if cmd then
    local buf = vim.api.nvim_get_current_buf()
    local input = table.concat(vim.api.nvim_buf_get_lines(buf, 0, -1, false), '\n') .. '\n'
    local result = vim.system(cmd, { stdin = input, text = true, cwd = root }):wait()
    if result.code ~= 0 then
      vim.notify((result.stderr or 'Formatter failed'):gsub('%s+$', ''), vim.log.levels.ERROR)
      return
    end
    local output = (result.stdout or ''):gsub('\r\n', '\n')
    if output == '' then return end
    local lines = vim.split(output, '\n', { plain = true })
    if lines[#lines] == '' then table.remove(lines) end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.notify('Formatted with ' .. cmd[1])
    return
  end

  for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
    if client:supports_method('textDocument/formatting') then
      vim.lsp.buf.format({ async = false })
      return
    end
  end
  vim.notify('No formatter for this file. See :TinyHealth', vim.log.levels.WARN)
end

vim.api.nvim_create_user_command('Format', format_buffer, { desc = 'Format current file' })
map('n', '<leader>cf', format_buffer, { desc = 'Format current file' })

local function project_test()
  local ft = vim.bo.filetype
  local root = project_root()
  local cmd
  if ft == 'rust' then cmd = { 'cargo', 'test' }
  elseif ft == 'go' then cmd = { 'go', 'test', './...' }
  elseif vim.tbl_contains({ 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' }, ft) then cmd = { 'npm', 'test' }
  elseif ft == 'python' then cmd = { 'python3', '-m', 'pytest' }
  end
  if not cmd or vim.fn.executable(cmd[1]) == 0 then
    vim.notify('No test command for this file. See :TinyHealth', vim.log.levels.WARN)
    return
  end
  vim.cmd('botright 12split')
  vim.cmd('enew')
  vim.fn.termopen(cmd, { cwd = root })
  vim.cmd('startinsert')
end

vim.api.nvim_create_user_command('ProjectTest', project_test, { desc = 'Run project tests in a terminal split' })
map('n', '<leader>tT', project_test, { desc = 'Run project tests' })

-- Neovim 0.11+ has a built-in LSP client. Each server starts only for its filetype.
local servers = {
  rust_analyzer = {
    cmd = { 'rust-analyzer' },
    filetypes = { 'rust' },
    root_markers = { 'Cargo.toml', 'rust-project.json', '.git' },
  },
  gopls = {
    cmd = { 'gopls' },
    filetypes = { 'go', 'gomod', 'gowork', 'gotmpl' },
    root_markers = { 'go.work', 'go.mod', '.git' },
  },
  ts_ls = {
    cmd = { 'typescript-language-server', '--stdio' },
    filetypes = { 'javascript', 'javascriptreact', 'typescript', 'typescriptreact' },
    root_markers = { 'tsconfig.json', 'jsconfig.json', 'package.json', '.git' },
  },
  pyright = {
    cmd = { 'pyright-langserver', '--stdio' },
    filetypes = { 'python' },
    root_markers = { 'pyproject.toml', 'setup.py', 'requirements.txt', '.git' },
  },
}

for name, config in pairs(servers) do
  if vim.fn.executable(config.cmd[1]) == 1 then
    vim.lsp.config(name, config)
    vim.lsp.enable(name)
  end
end

map('n', 'gd', vim.lsp.buf.definition, { desc = 'Go to definition' })
map('n', 'gr', vim.lsp.buf.references, { desc = 'Find references' })
map('n', '<leader>cr', vim.lsp.buf.rename, { desc = 'Rename symbol' })
map({ 'n', 'v' }, '<leader>ca', vim.lsp.buf.code_action, { desc = 'Code action' })
map('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous diagnostic' })
map('n', ']d', vim.diagnostic.goto_next, { desc = 'Next diagnostic' })
map('n', '<leader>cd', vim.diagnostic.open_float, { desc = 'Show diagnostic' })

vim.api.nvim_create_user_command('TinyHealth', function()
  local version = vim.version()
  local lines = { ('Neovim %d.%d.%d'):format(version.major, version.minor, version.patch), 'rg: ' .. (vim.fn.executable('rg') == 1 and 'ok' or 'missing') }
  for _, name in ipairs({ 'rust_analyzer', 'gopls', 'ts_ls', 'pyright' }) do
    local config = servers[name]
    lines[#lines + 1] = name .. ': ' .. (vim.fn.executable(config.cmd[1]) == 1 and 'ok' or 'missing')
  end
  lines[#lines + 1] = 'Project root: ' .. project_root()
  vim.notify(table.concat(lines, '\n'))
end, { desc = 'Check external commands used by this setup' })
