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

  outputs = { self, nixpkgs, hyprland, home-manager, ...}@inputs: {
    nixosConfigurations = {
     utm-vm = nixpkgs.lib.nixosSystem {
       system = "aarch64-linux";
       specialArgs = {inherit inputs;};
       modules = [
         ./hosts/utm-vm/configuration.nix
         hyprland.nixosModules.default
         home-manager.nixosModules.home-manager
         {
           nixpkgs.config.allowUnfree = true;
           home-manager.useGlobalPkgs = true;
           home-manager.useUserPackages = true;
           home-manager.backupFileExtension = "backup";
           home-manager.extraSpecialArgs = { inherit inputs; };
           home-manager.users.td = import ./users/td/home.nix;
         }
       ];
     };
     framework = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       specialArgs = {inherit inputs;};
       modules = [
         ./hosts/framework/configuration.nix
         hyprland.nixosModules.default
         home-manager.nixosModules.home-manager
         {
           nixpkgs.config.allowUnfree = true;
           home-manager.useGlobalPkgs = true;
           home-manager.useUserPackages = true;
           home-manager.backupFileExtension = "backup";
           home-manager.extraSpecialArgs = { inherit inputs; };
           home-manager.users.td = import ./users/td/home.nix;
         }
       ];
     };
     dl-prototype = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       specialArgs = {inherit inputs;};
       modules = [
         ./hosts/dl-prototype/configuration.nix
         hyprland.nixosModules.default
         home-manager.nixosModules.home-manager
         {
           nixpkgs.config.allowUnfree = true;
           home-manager.useGlobalPkgs = true;
           home-manager.useUserPackages = true;
           home-manager.backupFileExtension = "backup";
           home-manager.extraSpecialArgs = { inherit inputs; };
           home-manager.users.td = import ./users/td/home.nix;
         }
       ];
     };
    };
  };
}
