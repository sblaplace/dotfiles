{ config, pkgs, ... }:

{
  virtualisation.libvirtd.enable = true;
  programs.virt-manager.enable = true;
  
  users.users.laplace = {
    extraGroups = [ "libvirtd" ];
  };
}
