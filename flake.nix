{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    ghostty.url = "github:ghostty-org/ghostty";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      home-manager,
      treefmt-nix,
      sops-nix,
      ...
    }@inputs:
    let
      # Hosts span both x86_64 (framework, dl-prototype) and aarch64 (utm-vm).
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
      ];

      treefmtEval = forAllSystems (
        system: treefmt-nix.lib.evalModule nixpkgs.legacyPackages.${system} ./treefmt.nix
      );

      # All three hosts share the same home-manager wiring; only the
      # per-host configuration.nix and target system differ.
      mkHost =
        { hostname, system }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            ./hosts/${hostname}/configuration.nix
            sops-nix.nixosModules.sops
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
        utm-vm = mkHost {
          hostname = "utm-vm";
          system = "aarch64-linux";
        };

        # Primary x86_64 portable workstation (Framework 13).
        framework = mkHost {
          hostname = "framework";
          system = "x86_64-linux";
        };

        # High-performance x86_64 training rig (Threadripper + NVIDIA).
        dl-prototype = mkHost {
          hostname = "dl-prototype";
          system = "x86_64-linux";
        };
      };

      # `nix fmt` — runs nixfmt/statix/deadnix over the tree (see treefmt.nix).
      formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

      # `nix flake check` — validates formatting, plus (for free, via the
      # nixosConfigurations schema check) that all three hosts still evaluate.
      checks = forAllSystems (system: {
        formatting = treefmtEval.${system}.config.build.check self;

        # Docs drift is invisible until someone trusts a stale cheat sheet, so
        # assert the README's keybind table still matches hyprland.lua. Runs
        # standalone too: ./scripts/check-keybinds.sh
        keybindings = nixpkgs.legacyPackages.${system}.runCommand "check-keybindings" { } ''
          cd ${self}
          bash ${./scripts/check-keybinds.sh}
          touch $out
        '';
      });
    };
}
