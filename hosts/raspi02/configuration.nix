{ config, lib, pkgs, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/k3s/agent.nix
    ../../modules/hardware/raspberry-pi.nix
  ];

  networking.hostName = "raspi02";

  services.k3s.extraFlags = toString [
    "--node-label=node.kubernetes.io/instance-type=raspberry-pi"
    "--node-label=arch=arm64"
  ];
}