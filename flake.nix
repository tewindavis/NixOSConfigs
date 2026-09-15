{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    ghostty.url = "github:ghostty-org/ghostty";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, hyprland, home-manager, ... }@inputs:
    let
      # All three hosts share the same home-manager wiring; only the
      # per-host configuration.nix and target system differ.
      mkHost = { hostname, system }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            home-manager.nixosModules.home-manager
            {
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.backupFileExtension = "backup";
              home-manager.extraSpecialArgs = { inherit inputs; };
              home-manager.users.td = import ./users/td/home.nix;
            }
          ];
        };
    in
    {
      nixosConfigurations = {
        # Aarch64 sandbox optimized for MacOS/Apple Silicon (VirtIO/Spice).
        utm-vm = mkHost { hostname = "utm-vm"; system = "aarch64-linux"; };

        # Primary x86_64 portable workstation (Framework 13).
        framework = mkHost { hostname = "framework"; system = "x86_64-linux"; };

        # High-performance x86_64 training rig (Threadripper + NVIDIA).
        dl-prototype = mkHost { hostname = "dl-prototype"; system = "x86_64-linux"; };
      };
    };
}
