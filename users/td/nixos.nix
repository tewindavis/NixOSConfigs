{ pkgs, ... }:

{
  users.users.td = {
    isNormalUser = true;
    description = "td";
    extraGroups = [
      "networkmanager"
      "wheel"
      "video"
      "audio"
    ];
    shell = pkgs.zsh;

    # Inbound SSH is key-only (see modules/core/default.nix), so this list is
    # the *only* way into these hosts over the network — an empty list means
    # no remote access at all. This is td's own ed25519 key, matching
    # ~/.ssh/id_ed25519.pub on framework; verify with:
    #   diff <(cat ~/.ssh/id_ed25519.pub) <(grep -o 'ssh-ed25519 [^"]*' users/td/nixos.nix)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC2gsLe/uFP6iF+6wR1hRTcN/tNbPhc8lNAbk8QXcEef tewindavis@gmail.com"
    ];
  };
}
