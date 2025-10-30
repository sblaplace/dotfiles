{
  description = "Sarah's NixOS & K3s Cluster Configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager, disko, sops-nix, deploy-rs, ... }@inputs:
  let
    mkNixosSystem = { hostname, system ? "x86_64-linux", modules ? [] }:
      nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit inputs; };
        modules = [
          ./hosts/${hostname}/configuration.nix
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.laplace = import ./home/laplace.nix;
            home-manager.extraSpecialArgs = { inherit hostname; };
          }
        ] ++ modules;
      };
  in
  {
    nixosConfigurations = {
      # Control plane nodes
      neovenezia = mkNixosSystem { hostname = "neovenezia"; };
      raspi01 = mkNixosSystem { 
        hostname = "raspi01"; 
        system = "aarch64-linux";
      };
      
      # Worker nodes
      t450 = mkNixosSystem { hostname = "t450"; };
      precision7730 = mkNixosSystem { hostname = "precision7730"; };
      
      raspi02 = mkNixosSystem { hostname = "raspi02"; system = "aarch64-linux"; };
      raspi03 = mkNixosSystem { hostname = "raspi03"; system = "aarch64-linux"; };
      raspi04 = mkNixosSystem { hostname = "raspi04"; system = "aarch64-linux"; };
      # ... add more raspis
      
      jetson = mkNixosSystem { 
        hostname = "jetson"; 
        system = "aarch64-linux";
      };
    };

    # Development shell for direnv
    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      buildInputs = with nixpkgs.legacyPackages.x86_64-linux; [
        deploy-rs.packages.x86_64-linux.deploy-rs
        sops
        age
        git
        kubectl
        ssh-to-wip
      ];
      
      shellHook = ''
        echo "Cluster management shell ready."
      '';
    };

    # Deploy configuration
    deploy.nodes = {
      neovenezia = {
        hostname = "neovenezia.local";
        profiles.system = {
          user = "root";
          sshUser = "laplace";
          path = deploy-rs.lib.x86_64-linux.activate.nixos 
            self.nixosConfigurations.neovenezia;
        };
      };
      # ... repeat for all nodes
    };

    # Cluster management scripts
    apps.x86_64-linux = {
      # Deploy entire cluster
      deploy-cluster = {
        type = "app";
        program = toString (nixpkgs.legacyPackages.x86_64-linux.writeShellScript "deploy-cluster" ''
          echo "Deploying entire k3s cluster..."
          ${deploy-rs.packages.x86_64-linux.deploy-rs}/bin/deploy .
        '');
      };

      # Bootstrap cluster (first time only)
      bootstrap-cluster = {
        type = "app";
        program = toString (nixpkgs.legacyPackages.x86_64-linux.writeShellScript "bootstrap-cluster" ''
          set -e
          echo "Bootstrapping k3s cluster..."
          
          # Install control plane
          echo "Installing neovenezia (primary control plane)..."
          ./install.sh neovenezia 192.168.1.100 "disk-password"
          
          # Wait for k3s to be ready
          sleep 30
          
          # Install second control plane for HA
          echo "Installing raspi01 (secondary control plane)..."
          ./install.sh raspi01 192.168.1.51
          
          # Install workers
          echo "Installing workers..."
          ./install.sh t450 192.168.1.101
          ./install.sh precision7730 192.168.1.102
          ./install.sh raspi02 192.168.1.52
          # ... etc
          
          echo "Cluster bootstrapped!"
          echo "Check status with: kubectl get nodes"
        '');
      };
    };
  };
}
