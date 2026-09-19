{ config, pkgs, ... }:

{
  # Enable Hyprland at system level for SUID wrappers and system-wide integration
  programs.hyprland = {
    enable = true;
  };

  # Log in straight to Hyprland via a TUI greeter. --theme takes ANSI color
  # names, which resolve through console.colors (modules/core/default.nix),
  # so "blue" here is Tokyo Night's #7aa2f7. The greeting line (drawn in
  # `greet=blue`) names the machine and NixOS release, from this host's
  # own config.
  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.tuigreet}/bin/tuigreet --time --remember --remember-session --asterisks --greeting '${config.networking.hostName} · NixOS ${config.system.nixos.release}' --theme 'border=blue;title=blue;text=white;greet=blue;prompt=green;input=white;time=yellow;action=blue;button=yellow;container=black' --cmd start-hyprland";
      };
    };
  };

  # Wayland hardware-specific environment variables (System Level)
  environment.sessionVariables = {
    # If using NVIDIA, these are crucial
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER_ALLOW_SOFTWARE = "1";

    # Hint for electron apps
    NIXOS_OZONE_WL = "1";

    # Force dark mode for apps that check these vars
    GTK_THEME = "adw-gtk3-dark";

    # Explicit cursor size (matches gtk.cursorTheme.size/dconf cursor-size in
    # home.nix) so non-GTK/Wayland-native clients render it consistently too
    XCURSOR_SIZE = "24";
  };

  # Screensharing and Portal
  # xdg-desktop-portal-hyprland provides ScreenCast/Screenshot (needed for
  # screen sharing in Brave/Discord/OBS etc. over wlr-screencopy); gtk
  # handles FileChooser and everything else hyprland's portal doesn't
  # implement. Explicit preference order (rather than "*") avoids the two
  # portals racing/prompting for the same interface.
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = [
      "hyprland"
      "gtk"
    ];
  };

  # swayosd's udev rule grants the "video" group (td is a member, see
  # users/td/nixos.nix) write access to /sys/class/backlight for its
  # volume/brightness OSD (swayosd-server, started per-user in home.nix).
  services.udev.packages = [ pkgs.swayosd ];

  # Polkit GUI agent: without one, privileged GUI actions (Thunar mounting
  # internal/LUKS drives, GParted, fwupd's updater) silently fail since
  # nothing is listening to show the auth prompt. hyprpolkitagent is the
  # Hypr ecosystem's own agent; autostarted per-session in hyprland.lua.
  security.polkit.enable = true;
  environment.systemPackages = [ pkgs.hyprpolkitagent ];

  # Secret-service keyring, so Brave/git-credential/etc. can store logins
  # instead of nagging about a locked keyring. Auto-unlocks on login by
  # wiring PAM into greetd's session (the actual login path here, since
  # this config uses greetd/tuigreet rather than a "login" getty).
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.greetd.enableGnomeKeyring = true;
  # gnome-keyring.enable defaults this on, but it conflicts with
  # programs.ssh.startAgent (modules/core/default.nix) — only one SSH agent
  # can be active, and the plain one is already working, so keep it and only
  # use gnome-keyring for the secrets/login-credential portion.
  services.gnome.gcr-ssh-agent.enable = false;
}
