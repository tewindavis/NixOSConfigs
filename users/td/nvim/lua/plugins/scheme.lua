-- Scheme (SICP) support: highlighting, paren handling and an MIT Scheme REPL,
-- but deliberately no completion — see the blink.cmp spec at the bottom.
--
-- The interpreter itself is `pkgs.mitscheme` in home.nix, which provides the
-- `mit-scheme` binary Conjure launches.
return {
  -- Highlighting and structural motions both come from the treesitter
  -- grammar, so the parser is the one hard requirement here.
  -- LazyVim declares `opts_extend = { "ensure_installed" }` for this spec, so
  -- a plain list here is appended to its defaults rather than replacing them.
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "scheme" } },
  },

  -- Nesting depth by colour, in the same palette as the rest of the desktop.
  -- Reading Lisp without this is counting brackets by hand.
  {
    "HiPhish/rainbow-delimiters.nvim",
    ft = { "scheme", "lisp" },
    config = function()
      local palette = {
        "#7aa2f7", -- blue
        "#9ece6a", -- green
        "#ff9e64", -- orange
        "#bb9af7", -- purple
        "#7dcfff", -- cyan
        "#e0af68", -- yellow
        "#f7768e", -- red (deepest nesting; also what mismatches show as)
      }
      local names = {}
      for i, color in ipairs(palette) do
        local name = "RainbowDelimiter" .. i
        vim.api.nvim_set_hl(0, name, { fg = color })
        names[i] = name
      end
      require("rainbow-delimiters.setup").setup({ highlight = names })
    end,
  },

  -- Structural editing: slurp/barf, drag forms, wrap/unwrap. Keeps parens
  -- balanced while editing rather than fixing them up afterwards. It already
  -- lists scheme among its supported filetypes, so this only gates loading.
  {
    "julienvincent/nvim-paredit",
    ft = { "scheme", "lisp" },
    opts = {},
  },

  -- REPL. Conjure's scheme client is written for MIT Scheme specifically and
  -- already defaults its command to "mit-scheme"; it's set explicitly so the
  -- dependency on home.nix's `pkgs.mitscheme` is visible from here.
  --
  -- Mappings are all under `<localleader>` (LazyVim leaves that as `\`):
  -- `ee` evaluates the form under the cursor, `er` the outermost form, `ef`
  -- the file, `E` + a motion an arbitrary range, and `ls`/`lv` open the
  -- result log in a split. `:ConjureSchool` is an interactive tour.
  {
    "Olical/conjure",
    ft = { "scheme" },
    init = function()
      vim.g["conjure#client#scheme#stdio#command"] = "mit-scheme"
      -- Conjure's own completion source, off with everything else below.
      vim.g["conjure#completion#omnifunc"] = false
      -- Results in a floating log rather than a split stealing half the window.
      vim.g["conjure#log#hud#enabled"] = true
    end,
  },

  -- No autocompletion in Scheme buffers, by request: no popup while typing,
  -- and nothing to dismiss. Everything else keeps blink.cmp as usual.
  {
    "saghen/blink.cmp",
    opts = {
      enabled = function()
        return vim.bo.filetype ~= "scheme"
      end,
    },
  },
}
