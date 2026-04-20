{ config, pkgs, lib, ... }:

{
  imports = [
    ./hyprland.nix
  ];

  home.packages = with pkgs; [
    firefox
    obsidian
    signal-desktop
    blender
    qbittorrent
    discord
    mpv
    spotify
    onlyoffice-desktopeditors
    zotero
    krita
    freecad
    eog
    unrar
    ytdownloader
    godot_4
    logisim-evolution
    kicad
    gum
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    f3d
    kdePackages.kdenlive
    shotcut
    awscli2
    restic
  ];

  programs.firefox.enable = true;

  programs.mpv = {
    enable = true;
    config = {
      hwdec = "no";
      vo = "gpu";
    };
  };

  xdg.terminal-exec = {
    enable = true;
    settings = {
      default = [ "kitty.desktop" ];
    };
  };
}
