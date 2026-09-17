{ pkgs, ... }:

{
  imports = [ ./secrets.nix ];

  # Nix Settings
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Optimization and Garbage Collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;

  # Time and locale
  time.timeZone = "America/Chicago";
  i18n.defaultLocale = "en_US.UTF-8";

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # Essential System Services
  services.openssh.enable = true;
  networking.networkmanager.enable = true;

  # Keyboard
  services.xserver.xkb.options = "ctrl:nocaps";
  console.useXkbConfig = true;

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

  # Printing: CUPS + Avahi for zero-config discovery of network/AirPrint
  # printers. GTK/Qt print dialogs talk to CUPS automatically once enabled;
  # system-config-printer below is the GUI for adding/managing printers.
  services.printing = {
    enable = true;
    drivers = with pkgs; [ gutenprint ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
  environment.systemPackages = with pkgs; [
    git
    vim
    curl
    wget
    htop
    tree
    tmux
    pciutils
    system-config-printer
  ];

  system.stateVersion = "25.11";

  # SSH Agent
  programs.ssh.startAgent = true;

  # Enable Zsh
  programs.zsh.enable = true;

  # Enable dconf (needed for GTK/Theming)
  programs.dconf.enable = true;
}
