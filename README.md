# nvim-tiny

给 Linux 用的一套轻量 Neovim 配置。适合先练 Vim 键位，再逐步用它写 Rust、Go、Node.js 和 Python。浅色主题，带文件浏览器、项目搜索、轻量补全、格式化和测试入口。仓库只包含配置、中文速查表和用到的五个 `mini.nvim` Lua 模块，**没有二进制**。Neovim 启动和编辑时不访问网络。语言服务器由机器已有的命令提供，按打开的文件类型启动。

目标是 **Linux x86_64**，需要机器已有 Neovim 0.11+ 和 ripgrep 13.0.0+。安装不需要 root 权限，也不要求安装器联网。2 核 8G 的机器只会按打开的文件类型启动对应语言服务器。

## 获取与安装

```sh
git clone git@github.com:kumapower17/nvim-tiny.git
cd nvim-tiny
bash install.sh
~/.local/bin/nvim-tiny .
```

脚本会检查现有 Neovim 和 ripgrep 版本，然后将配置装到当前用户的 `~/.config/nvim-tiny`、插件装到 `~/.local/share/nvim-tiny`，再创建 `~/.local/bin/nvim-tiny` 启动命令（配置与数据目录遵守 `XDG_CONFIG_HOME`、`XDG_DATA_HOME`）。插件版本与配置内容相同时直接复用。不会覆盖已有的 `nvim` 命令。已有不同内容的目标文件时脚本停止；确认要升级时运行 `bash install.sh --force`，旧文件会改名备份。

更新时在仓库运行 `git pull`，再运行 `bash install.sh --force`。仓库中 `vendor/mini.nvim` 固定为 [mini.nvim v0.18.0](https://github.com/nvim-mini/mini.nvim/releases/tag/v0.18.0) 的五个模块和对应帮助文档，许可证保留在 [vendor/mini.nvim/LICENSE](vendor/mini.nvim/LICENSE)。

首次打开运行 `:Tutor` 学键位，之后运行 `:Keys` 打开[中文速查表](config/CHEATSHEET.md)。按空格、`g`、`z` 或 `Ctrl-w` 后稍停会出现后续键位提示。常用入口与 [LazyVim 键位](https://www.lazyvim.org/keymaps) 对齐：`<Space>ff` 模糊找文件、`<Space>sg` 搜内容、`<Space>e` 打开或关闭项目文件浏览器、`<Space>ft` 打开项目终端、`<Space>tT` 运行项目测试、`<Space>cf` 格式化。这些快捷键要先按 `Esc` 回到普通模式。文件浏览器里用 `j` / `k` 选择、`l` 进入、`h` 返回、`L` 打开文件并关闭、`g?` 查看帮助。`:Root` 切换项目根目录，`:TinyHealth` 检查外部命令。代码位置书签用 `mA` 设置、`` `A `` 跳转、`<Space>sm` 浏览列表；大写书签退出后保留。

## 语言服务器

这些命令在目标机器的 `PATH` 中出现时才启用：

| 语言 | 命令 | 常见来源 |
| --- | --- | --- |
| Rust | `rust-analyzer` | Rust 工具链的 rust-analyzer 组件 |
| Go | `gopls` | Go 工具链的 gopls |
| JavaScript / TypeScript | `typescript-language-server` | npm 包 `typescript-language-server` 与 `typescript` |
| Python | `pyright-langserver` | npm 包 `pyright` |

这些语言服务器可按需从各语言的工具链或包管理器安装。Node.js 与 Python 的语言服务器需要 Node.js；`gopls` 和 `rust-analyzer` 可能需要项目依赖或工具链在本机可用。没有语言服务器时，文件编辑、基本语法高亮、搜索、窗口和帮助仍能使用。`:checkhealth vim.lsp` 可确认当前文件是否连接到服务器。插入模式会延迟 250 ms 显示补全，也可用 `Ctrl-x Ctrl-o` 手动请求 LSP 补全。

`<Space>cf` 优先调用目标机器已有的 `rustfmt`、`gofmt`、`ruff` / `black`、项目内或全局的 `prettier`；缺少这些命令时尝试当前 LSP 的格式化能力。`<Space>tT` 分别运行 `cargo test`、`go test ./...`、`npm test`、`python3 -m pytest`，命令需要目标机器已有对应工具。

配置文件在 `config/init.lua`，可按需要删改键位或语言。
