{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/k3s/server.nix
    ../../modules/hardware/raspberry-pi.nix
  ];

  networking.hostName = "raspi01";

  # Join existing cluster as control plane
  services.k3s.extraFlags = toString [
    "--server=https://neovenezia.local:6443"
  ];
}
