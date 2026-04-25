{
  config,
  lib,
  pkgs,
  ...
}:

{
  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidia_x11;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];

  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_EnableGpuFirmware=0"
  ];

  hardware.nvidia-container-toolkit.enable = true;
}
