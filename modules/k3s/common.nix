{ config, lib, pkgs, ... }:

{
  # Common networking for all k3s nodes
  networking.firewall.allowedTCPPorts = [
    6443  # k3s API
    10250 # kubelet metrics
  ];

  # Disable swap (k8s requirement)
  swapDevices = [ ];

  # Enable cgroups v2
  systemd.enableUnifiedCgroupHierarchy = true;

  # Container runtime requirements
  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
    "net.bridge.bridge-nf-call-iptables" = 1;
    "net.bridge.bridge-nf-call-ip6tables" = 1;
  };

  # Load required kernel modules
  boot.kernelModules = [ "br_netfilter" "overlay" ];

  # Install useful k8s tools
  environment.systemPackages = with pkgs; [
    kubectl
    kubernetes-helm
    k9s
    kubeseal
    fluxcd
    argocd
  ];

  # Set up kubectl config for laplace
  environment.sessionVariables = {
    KUBECONFIG = "/etc/rancher/k3s/k3s.yaml";
  };
}