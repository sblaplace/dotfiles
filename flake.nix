{
  description = "Sarah's NixOS and Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }@inputs: {
    # NixOS configurations
    nixosConfigurations = {
      neovenezia = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/neovenezia/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.laplace = import ./home/laplace.nix;
            home-manager.extraSpecialArgs = { 
              hostname = "neovenezia"; 
            };
          }
        ];
      };

      t450 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/t450/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.laplace = import ./home/laplace.nix;
            home-manager.extraSpecialArgs = { 
              hostname = "t450"; 
            };
          }
        ];
      };

      precision7730 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/precision7730/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.laplace = import ./home/laplace.nix;
            home-manager.extraSpecialArgs = { 
              hostname = "precision7730"; 
            };
          }
        ];
      };
    };

    # Standalone home-manager for non-NixOS machines (Raspberry Pis)
    homeConfigurations = {
      "laplace@raspi01" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.aarch64-linux;
        modules = [
          ./home/laplace.nix
          { 
            home.username = "laplace";
            home.homeDirectory = "/home/laplace";
          }
        ];
        extraSpecialArgs = { 
          hostname = "raspi01";
        };
      };
      # Add more Raspberry Pis as needed
    };
  };
}
