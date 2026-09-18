-- LSP servers, formatters and linters are installed declaratively via Nix
-- (see the "Neovim LSP servers" section of ../../../home.nix) instead of
-- by Mason, so editor tooling stays reproducible with nixos-rebuild rather
-- than drifting from whatever Mason downloaded into ~/.local/share/nvim at
-- runtime. Disabling these just turns off the auto-installer: nvim-lspconfig,
-- conform.nvim and nvim-lint all fall back to calling the binaries straight
-- off PATH, which is exactly what we want since Nix already put them there.
return {
  { "mason-org/mason.nvim", enabled = false },
  { "mason-org/mason-lspconfig.nvim", enabled = false },
  { "WhoIsSethDaniel/mason-tool-installer.nvim", enabled = false },
  { "jay-babu/mason-nvim-dap.nvim", enabled = false },
}
