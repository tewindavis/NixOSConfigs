local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ~/.config/nvim/lazy-lock.json is a read-only Home Manager symlink into the
-- store, so `:Lazy update` would move the installed plugins but fail to
-- record them, leaving this host silently ahead of the lock the other hosts
-- install from. Point lazy at the repo's copy instead: updates then show up
-- in `git status` in /etc/nixos, to commit or `git checkout` + `:Lazy restore`.
-- Hosts without a checkout fall back to lazy's default (the store symlink).
local repo_lock = "/etc/nixos/users/td/nvim/lazy-lock.json"
local lockfile = vim.uv.fs_access(repo_lock, "W") and repo_lock or nil

require("lazy").setup({
  spec = {
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- Language extras: LSP + formatting + linting + treesitter for
    -- everything this system has a toolchain for (see the "Languages &
    -- Toolchains" and "Neovim LSP servers" sections of ../../../home.nix).
    -- Servers/formatters run straight off PATH — Mason is disabled in
    -- plugins/mason.lua.
    { import = "lazyvim.plugins.extras.lang.rust" },
    { import = "lazyvim.plugins.extras.lang.zig" },
    { import = "lazyvim.plugins.extras.lang.python" },
    { import = "lazyvim.plugins.extras.lang.clangd" },
    { import = "lazyvim.plugins.extras.lang.nix" },
    -- Config-file ecosystem that shows up alongside the above (Cargo.toml,
    -- pyproject.toml, flake inputs, CI yaml, docs).
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    -- Import your plugins
    { import = "plugins" },
    { "ThePrimeagen/vim-be-good", cmd="VimBeGood" }
  },
  defaults = {
    lazy = false,
    version = false, -- always use the latest git commit
  },
  lockfile = lockfile,
  install = { colorscheme = { "tokyonight", "habamax" } },
  checker = { enabled = true },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
