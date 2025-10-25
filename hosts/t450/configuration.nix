{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/k3s/agent.nix
  ];

  networking.hostName = "t450";

  services.k3s.extraFlags = toString [
    "--node-taint=node-role.kubernetes.io/laptop=true:NoSchedule"
    "--node-label=node-role.kubernetes.io/laptop=true"
  ];
}