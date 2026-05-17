{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    hyprland.url = "github:hyprwm/Hyprland";
    ghostty.url = "github:ghostty-org/ghostty";
  };

  outputs = { self, nixpkgs, hyprland, ...}@inputs: {
    nixosConfigurations = {
     utm-vm = nixpkgs.lib.nixosSystem {
       # May we never be forced to use x86 again...
       system = "aarch64-linux";
       specialArgs = {inherit inputs;};
       modules = [
         ./hosts/utm-vm/configuration.nix
         hyprland.nixosModules.default
       ];
     };
     framework = nixpkgs.lib.nixosSystem {
       system = "x86_64-linux";
       specialArgs = {inherit inputs;};
       modules = [
         ./hosts/framework/configuration.nix
         hyprland.nixosModules.default
       ];
    };
  };
}
