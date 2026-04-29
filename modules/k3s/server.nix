{ config, lib, pkgs, ... }:

{
  imports = [ ./common.nix ];

  services.k3s = {
    enable = true;
    role = "server";
    
    extraFlags = [
      # DISABLE k3s default CNI (flannel)
      "--flannel-backend=none"
      "--disable-network-policy"
      
      # Don't install kube-proxy (Cilium replaces it)
      "--disable=traefik"  # Optional: use Cilium Ingress instead
      
      # Cilium needs this
      "--kube-proxy-arg=proxy-mode=iptables"  # Actually won't be used, but needs to be set
      
      # Cluster settings
      "--cluster-cidr=10.42.0.0/16"
      "--service-cidr=10.43.0.0/16"
      
      # TLS SAN
      "--tls-san=neovenezia.local"
      "--tls-san=k3s.local"
      
      # Node labels
      "--node-label=node-role.kubernetes.io/control-plane=true"
    ];

    tokenFile = config.sops.secrets.k3s-server-token.path;
  };

  # Cilium CLI tool
  environment.systemPackages = with pkgs; [
    cilium-cli
    hubble
  ];

  networking.firewall = {
    allowedTCPPorts = [
      6443   # k3s API
      2379   # etcd client
      2380   # etcd peer
      4240   # Cilium health checks
      4244   # Hubble server
      4245   # Hubble Relay
    ];
    allowedUDPPorts = [
      8472   # Cilium VXLAN (overlay mode)
      51871  # WireGuard (if using encryption)
    ];
  };
}