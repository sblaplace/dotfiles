{ config, pkgs, ... }:
{
  # Headless server config
  services.xserver.enable = false;
  
  # Serial console for Raspberry Pi
  boot.kernelParams = [ "console=ttyS0,115200n8" ];
  
  # Reduce power consumption
  powerManagement.cpuFreqGovernor = "ondemand";
}