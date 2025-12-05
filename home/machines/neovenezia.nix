{ config, pkgs, lib, ... }:

{
  # Add packages specific to your desktop
  home.packages = with pkgs; [
    nvtopPackages.nvidia
    unityhub
    lmstudio
    vscode
    protonvpn-gui
    protonvpn-cli
    umu-launcher
  ];

  # Maybe different kitty font size for the big monitor
  programs.kitty.settings.font_size = lib.mkForce 12;
}
