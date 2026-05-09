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
}
