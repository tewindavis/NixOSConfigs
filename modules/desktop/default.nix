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
  environment.systemPackages = with pkgs; [
    xarchiver
    p7zip
    unrar
    unzip
    zip
  ];
}
