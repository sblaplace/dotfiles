{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.raspberry-pi."4".apply-overlays-dtmerge.enable = true;
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;
}
