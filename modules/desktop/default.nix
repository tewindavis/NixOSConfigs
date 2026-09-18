{ pkgs, ... }:

{
  imports = [
    ./hyprland.nix
  ];

  # Global desktop settings (e.g., Fonts)
  fonts.packages = with pkgs; [
    nerd-fonts.fira-code
    nerd-fonts.jetbrains-mono
    nerd-fonts.zed-mono
    noto-fonts-color-emoji
  ];

  # Enable Thunar and related services
  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images

  # Archive support: thunar-archive-plugin (above) only wires the Thunar
  # context menu up — it still shells out to an actual archive manager (GUI)
  # and command-line backends for the individual formats.
  # p7zip is deliberately absent: it's the p7zip-project fork, pinned at
  # 17.06 (upstream's last release), carrying zero patches in nixpkgs while
  # official 7-Zip has moved to 26.x. Fixes like CVE-2026-48095 (heap
  # overflow in the NTFS handler, RCE, fixed in 7-Zip 26.01) will never reach
  # it. `_7zz` is the maintained official CLI.
  #
  # Overriding xarchiver's `p7zip` argument is the part that actually matters:
  # xarchiver wraps itself with its own archive backends via wrapProgram, so
  # dropping p7zip from the list below alone would leave p7zip on xarchiver's
  # PATH and still handle every .7z opened from Thunar. xarchiver probes for
  # `7zz` *before* `7z`/`7za`/`7zr` (src/main.c), so _7zz drops straight in.
  # See docs/gotchas.md.
  environment.systemPackages = with pkgs; [
    (xarchiver.override { p7zip = _7zz; })
    _7zz
    unrar
    unzip
    zip
  ];
}
