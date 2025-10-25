{ config, pkgs, ... }:

{
  # Add packages specific to your desktop
  home.packages = with pkgs; [
    nvtopPackages.nvidia
    unityhub
    lmstudio
    vscode
    protonvpn-gui
    umu-launcher
  ];

  # Maybe different kitty font size for the big monitor
  programs.kitty.settings.font_size = lib.mkForce 12;
}
