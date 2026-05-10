{ pkgs, ... }:

{
  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes"];
  
  # Time and locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # User Account
  users.users.td = {
    isNormalUser = true;
    description = "td";
    extraGroups = [ "networkmanager" "wheel" "video" ];
    # Use a basic shell for now
    shell = pkgs.bash;
  };

  # System-wide packages
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    tree
    tmux
    pciutils
  ];

  # Allow unfree packages (needed for nvidia)
  nixpkgs.config.allowUnfree = true;

  # Essential System Services
  services.openssh.enable = true; # so we can SSH in if the display dies
  networking.networkmanager.enable = true;
  
  system.stateVersion = "25.11";

  # start up the ssh agent
  programs.ssh = {
    startAgent = true;
  };      

}
