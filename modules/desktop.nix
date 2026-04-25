{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Force non-uwsm Hyprland session; uwsm wrapper is broken in this nixpkgs
  # (it tries to start a missing systemd user unit).
  services.displayManager.defaultSession = "hyprland";

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput.enable = true;

  # Bluetooth support
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;

  # Still needed for XWayland
  services.xserver.enable = true;

  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    WLR_NO_HARDWARE_CURSORS = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-color-emoji
    corefonts
    (nerd-fonts.fira-code)
  ];

  security.pam.services.hyprland.enableGnomeKeyring = true;
  services.gnome.gnome-keyring.enable = true;
}
