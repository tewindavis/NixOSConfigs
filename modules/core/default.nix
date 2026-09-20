{ lib, pkgs, ... }:

{
  imports = [
    ./secrets.nix
    ./failure-notify.nix
  ];

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
  # Key-only SSH. A bare `services.openssh.enable = true` leaves
  # PasswordAuthentication and KbdInteractiveAuthentication at their upstream
  # default of `true` and opens port 22 on every interface — which on a
  # laptop that roams onto café/hotel/conference networks means anyone on the
  # LAN can attempt online password guessing against `td`, and `td` is in
  # `wheel` with `sudo` gated by that same password. `td`'s public key is
  # declared in users/td/nixos.nix; keep at least one recipient there before
  # switching, since with password auth off an empty key list locks out
  # remote access entirely (console/physical login is unaffected). framework
  # additionally closes port 22 and listens on loopback only, in its own
  # configuration.nix.
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };
  networking.networkmanager.enable = true;

  # Keyboard
  services.xserver.xkb.options = "ctrl:nocaps";
  console.useXkbConfig = true;

  # TTY palette: Ghostty's Tokyo Night ANSI colors (users/td/ghostty/config),
  # in the same 0-15 order. tuigreet's --theme color names resolve through
  # this too.
  console.colors = [
    "15161e"
    "f7768e"
    "9ece6a"
    "e0af68"
    "7aa2f7"
    "bb9af7"
    "7dcfff"
    "a9b1d6"
    "414868"
    "f7768e"
    "9ece6a"
    "e0af68"
    "7aa2f7"
    "bb9af7"
    "7dcfff"
    "c0caf5"
  ];

  # Boot splash + silent boot. Catppuccin Mocha is the closest packaged
  # theme to Tokyo Night, and matches the catppuccin cursor in home.nix.
  # The systemd initrd is what lets plymouth draw the LUKS passphrase prompt
  # on framework instead of dropping back to text for it; its emergency
  # shell stays off (boot.initrd.systemd.emergencyAccess defaults to false).
  boot.plymouth = {
    enable = true;
    theme = "catppuccin-mocha";
    themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
  };
  boot.initrd.systemd.enable = true;
  boot.consoleLogLevel = 3;
  boot.initrd.verbose = false;
  boot.kernelParams = [
    "quiet"
    "splash"
    "udev.log_level=3"
    "rd.udev.log_level=3"
    "systemd.show_status=auto"
  ];

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
    # cups-browsed (on by default whenever avahi is) auto-creates a local
    # queue for every printer advertised on the LAN — the entry point of the
    # 2024 cups-browsed/foomatic-rip RCE chain, where a rogue "printer"
    # supplies the PPD. Not needed for discovery: CUPS itself is built with
    # DNS-SD and shows AirPrint/IPP Everywhere printers in print dialogs as
    # temporary queues, and system-config-printer can still add them.
    browsed.enable = false;
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    # UDP 5353. mkDefault so a host can close it (framework does).
    openFirewall = lib.mkDefault true;
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

  # An agent alone isn't enough for a passphrase-protected key: something has
  # to be able to *ask* for the passphrase. enableAskPassword defaults to
  # services.xserver.enable, which is false here (greetd + Hyprland, no
  # xserver), so SSH_ASKPASS went unset and ssh fell back to a compiled-in
  # path that doesn't exist on NixOS — any non-TTY caller (a GUI app, or a
  # command run without a controlling terminal) died with
  # "ssh_askpass: exec(): No such file or directory" instead of prompting.
  # seahorse's askpass is GTK, so it inherits the adw-gtk3-dark/Papirus
  # theming from home.nix; the default x11-ssh-askpass would need XWayland.
  programs.ssh.enableAskPassword = true;
  programs.ssh.askPassword = "${pkgs.seahorse}/libexec/seahorse/ssh-askpass";

  # Unlock once per login session instead of once per operation: the first
  # ssh/git command to need the key prompts, and the decrypted key is handed
  # to the agent started above for the rest of the session.
  programs.ssh.extraConfig = ''
    AddKeysToAgent yes
  '';

  # Enable Zsh
  programs.zsh.enable = true;

  # Enable dconf (needed for GTK/Theming)
  programs.dconf.enable = true;
}
