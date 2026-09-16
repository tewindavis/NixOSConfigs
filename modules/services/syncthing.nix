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
  };
}
