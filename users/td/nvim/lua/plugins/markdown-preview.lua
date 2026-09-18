-- markdown-preview.nvim is disabled: it arrives via LazyVim's
-- `lang.markdown` extra (see ../config/lazy.lua) and reaches around Nix to
-- fetch and execute a binary at install time. (blink.cmp also downloads a
-- prebuilt library, but from an active upstream; see docs/gotchas.md.) Its
-- build step downloads a prebuilt Node/Next.js server from the upstream
-- GitHub releases API with no checksum and no signature, and upstream has
-- been dormant since 2023 (last commit 2023-10-17, last release v0.0.10 from
-- 2022-05-13) — so the binary that lands in app/bin/ is a 2022 runtime from
-- an unmaintained repo, outside the reproducibility guarantee the rest of
-- this config's editor tooling has. See docs/gotchas.md.
--
-- render-markdown.nvim (installed, actively maintained, pure Lua) covers
-- in-buffer markdown rendering, which is what this was being used for.
return {
  { "iamcco/markdown-preview.nvim", enabled = false },
}
