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

  # Stand alone programs I don't want to mess with much
  environment.systemPackages = with pkgs; [
    brave
    libva-utils # for checking hardware acceleration
  ];


}
