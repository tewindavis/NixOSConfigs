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
  # Key-only SSH. A bare `services.openssh.enable = true` leaves
  # PasswordAuthentication and KbdInteractiveAuthentication at their upstream
  # default of `true` and opens port 22 on every interface — which on a
  # laptop that roams onto café/hotel/conference networks means anyone on the
  # LAN can attempt online password guessing against `td`, and `td` is in
  # `wheel` with `sudo` gated by that same password. `td`'s public key is
  # declared in users/td/nixos.nix; keep at least one recipient there before
  # switching, since with password auth off an empty key list locks out
  # remote access entirely (console/physical login is unaffected).
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
