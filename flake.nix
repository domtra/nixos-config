{
  description = "UM790 Pro NixOS Workstation Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, disko, home-manager, ... }: {
    nixosConfigurations.um790 = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        ./hosts/um790/configuration.nix
        ./hosts/um790/disko.nix
        ./hosts/um790/hardware-configuration.nix
        {
          # Global flakes and nix-command
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          
          # Allow unfree packages
          nixpkgs.config.allowUnfree = true;
          
          # Home Manager configuration
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            users.dom = import ./home/dom/home.nix;
          };
        }
      ];
    };
  };
}