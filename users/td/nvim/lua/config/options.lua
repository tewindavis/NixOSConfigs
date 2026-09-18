-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add your own options here

-- lang.python extra defaults to pyright; basedpyright is the actively
-- maintained fork we install instead (see home.nix). Must be set before
-- lazy.nvim evaluates the extra, so it belongs here rather than in plugins/.
vim.g.lazyvim_python_lsp = "basedpyright"
