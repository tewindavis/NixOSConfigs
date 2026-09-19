-- Start screen header: block-letter NIXOS, each row one step along the
-- desktop's blue -> green border gradient (#7aa2f7 -> #9ece6a). snacks'
-- plain `header` section takes a single highlight, so each row is its own
-- text section with its own highlight group. Keys and startup sections are
-- snacks' defaults, which LazyVim uses unchanged.
local rows = {
  "███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗",
  "████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝",
  "██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗",
  "██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║",
  "██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║",
  "╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝",
}
local gradient = { "#7aa2f7", "#81abdb", "#88b4bf", "#90bca2", "#97c586", "#9ece6a" }

local function set_highlights()
  for i, color in ipairs(gradient) do
    vim.api.nvim_set_hl(0, "DashboardNixos" .. i, { fg = color, bold = true })
  end
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      set_highlights()
      -- Colorschemes clear custom groups when they load; set them again.
      vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

      local sections = {}
      for i, row in ipairs(rows) do
        table.insert(sections, {
          text = { { row, hl = "DashboardNixos" .. i } },
          align = "center",
          padding = i == #rows and 2 or 0,
        })
      end
      table.insert(sections, { section = "keys", gap = 1, padding = 1 })
      table.insert(sections, { section = "startup" })

      opts.dashboard = opts.dashboard or {}
      opts.dashboard.sections = sections
    end,
  },
}
