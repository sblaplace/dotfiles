{ config, pkgs, ... }:
{
  nix.settings = {
    experimental-features = [ "nix-command" "flakes" ];
    auto-optimise-store = true;
  };

  # Common packages on all systems
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    git
    htop
    docker-compose
    docker
    bun
  ];

  # SSH access
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
    };
  };

  hardware.nvidia-container-toolkit.enable = true;

  # User configuration moved to host-specific files
  # Define users.users.laplace in each host's configuration.nix instead

  # Automatic garbage collection
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "25.05";
}
