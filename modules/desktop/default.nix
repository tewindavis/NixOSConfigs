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
    xfce.thunar-archive-plugin
    xfce.thunar-volman
  ];
  services.gvfs.enable = true; # Mount, trash, and other functionalities
  services.tumbler.enable = true; # Thumbnail support for images
}
