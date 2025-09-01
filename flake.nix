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

  outputs = { self, nixpkgs, disko, home-manager, ... }:
  let
    system = "x86_64-linux";
    
    # Single nixpkgs instance with shared config
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    
    # Single home modules definition  
    homeModules = [ ./home/dom/home.nix ];
    
    # Single home configuration that both paths use
    homeConfiguration = home-manager.lib.homeManagerConfiguration {
      inherit pkgs;
      modules = homeModules;
    };
  in {
    nixosConfigurations.um790 = nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        disko.nixosModules.disko
        home-manager.nixosModules.home-manager
        ./hosts/um790/configuration.nix
        ./hosts/um790/disko.nix
        ./hosts/um790/hardware-configuration.nix
        {
          # Global flakes and nix-command
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          
          # Use the SAME pkgs instance (inherits allowUnfree automatically)
          nixpkgs.pkgs = pkgs;
          
          # Home Manager configuration
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            # Import the SAME modules
            users.dom = { imports = homeModules; };
          };
        }
      ];
    };
    
    # Reuse the exact same configuration
    homeManagerConfigurations."dom@um790" = homeConfiguration;
    "dom@um790" = homeConfiguration.activationPackage;
  };
}