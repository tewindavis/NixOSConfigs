-- LazyVim defaults tokyonight to the "moon" variant; the rest of the desktop
-- (Ghostty, waybar, dunst, ...) uses "night". Transparent so Ghostty's
-- translucent, blurred background shows through like it does in the shell.
-- Floats keep their solid background so popups stay readable over text.
return {
  {
    "folke/tokyonight.nvim",
    opts = {
      style = "night",
      transparent = true,
      styles = {
        sidebars = "transparent",
      },
    },
  },
}
