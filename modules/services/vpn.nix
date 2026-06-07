{ pkgs, ... }:

{
  # Mullvad VPN
  # This enables the daemon and the CLI tool. 
  # You can also use the Mullvad GUI by adding the package.
  services.mullvad-vpn.enable = true;
  services.mullvad-vpn.package = pkgs.mullvad-vpn;

  # Essential for proper DNS handling when using VPNs
  services.resolved.enable = true;

  # Proton VPN & Mullvad GUI
  environment.systemPackages = with pkgs; [
    protonvpn-gui
    proton-vpn-cli
    mullvad-vpn # Graphical client
  ];
}
