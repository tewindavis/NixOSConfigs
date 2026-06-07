{ pkgs, ... }:

{
  # Nix Settings
  nix.settings.experimental-features = [ "nix-command" "flakes"];
  
  # Time and locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Essential System Services
  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  # Hardware/Firmware
  hardware.enableRedistributableFirmware = true;

  # Audio (Pipewire)
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  
  system.stateVersion = "25.11";

  # SSH Agent
  programs.ssh.startAgent = true;

  # Enable Zsh
  programs.zsh.enable = true;

  # Enable dconf (needed for GTK/Theming)
  programs.dconf.enable = true;
}
