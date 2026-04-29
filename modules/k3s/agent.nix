{ config, lib, pkgs, ... }:

{
  imports = [ ./common.nix ];

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://neovenezia.local:6443";
    tokenFile = config.sops.secrets.k3s-agent-token.path;
    
    extraFlags = [
      # Disable flannel
      "--flannel-backend=none"
    ];
  };

  environment.systemPackages = with pkgs; [
    cilium-cli
  ];
}