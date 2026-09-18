_:

{
  # LAN/P2P file sync (Syncthing). Web GUI on localhost:8384; syncthingtray
  # (users/td/home.nix) gives a waybar tray icon so it doesn't require
  # opening a browser for status/control.
  services.syncthing = {
    enable = true;
    user = "td";
    dataDir = "/home/td"; # configDir defaults to dataDir + "/.config/syncthing"
    openDefaultPorts = true;
    # Devices and folders are managed in the GUI, not declared here. Both
    # options default to true, meaning "delete anything not declared in
    # settings.*" — inert only while nothing is declared (the module skips
    # its config push when settings is empty). Pinned false so that adding
    # any services.syncthing.settings.* later merges with the GUI state
    # instead of silently wiping GUI-added folders and devices.
    overrideDevices = false;
    overrideFolders = false;
  };
}
