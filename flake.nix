{
  description = "UM790 Pro NixOS Workstation Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # walker = {
    #   url = "github:abenz1267/walker";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Apple Silicon (Asahi) support module
    nixos-apple-silicon = {
      url = "github:nix-community/nixos-apple-silicon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      disko,
      home-manager,
      darwin,
      nixos-apple-silicon,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      systemAarch64 = "aarch64-linux";
      systemDarwin = "aarch64-darwin";

      nixpkgsConfig = {
        allowUnfree = true;
        permittedInsecurePackages = [
          "beekeeper-studio-5.3.4"
        ];
      };

      # Single nixpkgs instances with shared config
      pkgs = import nixpkgs {
        inherit system;
        config = nixpkgsConfig;
      };
      pkgsAarch64 = import nixpkgs {
        system = systemAarch64;
        config = nixpkgsConfig;
      };
      pkgsDarwin = import nixpkgs {
        system = systemDarwin;
        config = nixpkgsConfig;
      };

      # Single home modules definition
      homeModules = [ ./home/dom/home.nix ];

      # Single home configuration that both paths use
      homeConfiguration = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = homeModules;
        extraSpecialArgs = { inherit inputs; };
      };

      homeConfigurationAarch64 = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsAarch64;
        modules = homeModules;
        extraSpecialArgs = { inherit inputs; };
      };

      # New home profiles
      homeModulesCommon = [ ./home/dom/common.nix ];
      homeModulesVm = homeModulesCommon ++ [ ./home/dom/vm.nix ];
      homeModulesHost = homeModulesCommon ++ [ ./home/dom/host.nix ];

      homeConfigurationVm = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsAarch64;
        modules = homeModulesVm;
        extraSpecialArgs = { inherit inputs; };
      };

      homeConfigurationHost = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgsDarwin;
        modules = homeModulesHost;
        extraSpecialArgs = { inherit inputs; };
      };
    in
    {
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
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            # Use the SAME pkgs instance (inherits allowUnfree automatically)
            nixpkgs.pkgs = pkgs;

            # Home Manager configuration
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              # Import the SAME modules with inputs
              users.dom = {
                imports = homeModules;
              };
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };

      # Apple Silicon MacBook Air (M1) host
      nixosConfigurations."mba-m1" = nixpkgs.lib.nixosSystem {
        system = systemAarch64;
        modules = [
          home-manager.nixosModules.home-manager
          # Asahi / Apple Silicon support
          nixos-apple-silicon.nixosModules.apple-silicon-support
          # Overlay provides kernel, mesa, u-boot bits when needed
          (
            { config, pkgs, ... }:
            {
              nixpkgs.overlays = [ nixos-apple-silicon.overlays.apple-silicon-overlay ];
            }
          )
          ./hosts/mba-m1/configuration.nix
          ./hosts/mba-m1/hardware-configuration.nix
          {
            # Global flakes and nix-command
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];

            # Use the SAME pkgs instance (inherits allowUnfree automatically)
            nixpkgs.pkgs = pkgsAarch64;

            # Home Manager configuration
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.dom = {
                imports = homeModules ++ [ ./hosts/mba-m1/home-overrides.nix ];
              };
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };

      # VMware Fusion Dev VM (Apple Silicon host, aarch64 guest)
      nixosConfigurations."vm-fusion" = nixpkgs.lib.nixosSystem {
        system = systemAarch64;
        modules = [
          home-manager.nixosModules.home-manager
          ./hosts/vm-fusion-aarch64/configuration.nix
          ./hosts/vm-fusion-aarch64/hardware-configuration.nix
          {
            nix.settings.experimental-features = [
              "nix-command"
              "flakes"
            ];
            nixpkgs.pkgs = pkgsAarch64;
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.dom = {
                imports = homeModulesVm;
              };
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };

      # macOS host (M4 Pro) managed with nix-darwin + Home Manager
      darwinConfigurations."macbook-pro-m4" = darwin.lib.darwinSystem {
        system = systemDarwin;
        modules = [
          home-manager.darwinModules.home-manager
          ./hosts/darwin-mbp/configuration.nix
          {
            nixpkgs.config = nixpkgsConfig;
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              users.dom = {
                imports = homeModulesHost;
              };
              extraSpecialArgs = { inherit inputs; };
            };
          }
        ];
      };

      # Reuse the exact same configuration
      homeManagerConfigurations."dom@um790" = homeConfiguration;
      "dom@um790" = homeConfiguration.activationPackage;

      # AArch64 Home Manager build for the MacBook Air
      homeManagerConfigurations."dom@mba-m1" = homeConfigurationAarch64;
      "dom@mba-m1" = homeConfigurationAarch64.activationPackage;

      # Home Manager builds for new profiles
      homeManagerConfigurations."dom@vm-fusion" = homeConfigurationVm;
      "dom@vm-fusion" = homeConfigurationVm.activationPackage;

      homeManagerConfigurations."dom@macbook-pro-m4" = homeConfigurationHost;
      "dom@macbook-pro-m4" = homeConfigurationHost.activationPackage;
    };
}
