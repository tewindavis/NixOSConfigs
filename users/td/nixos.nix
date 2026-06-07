{ pkgs, ... }:

{
  users.users.td = {
    isNormalUser = true;
    description = "td";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" ];
    shell = pkgs.zsh;
  };
}
