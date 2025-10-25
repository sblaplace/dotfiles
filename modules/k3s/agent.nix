{ config, lib, pkgs, ... }:

{
  imports = [ ./common.nix ];

  services.k3s = {
    enable = true;
    role = "agent";
    serverAddr = "https://neovenezia.local:6443";
    tokenFile = config.sops.secrets.k3s-agent-token.path;
    
    extraFlags = toString [
      # Disable flannel
      "--flannel-backend=none"
    ];
  };

  # Same kernel config as server
  boot.kernelModules = [ "br_netfilter" "overlay" ];
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.ipv4.conf.all.forwarding" = 1;
    "net.ipv6.conf.all.forwarding" = 1;
  };

  environment.systemPackages = with pkgs; [
    cilium-cli
  ];
}