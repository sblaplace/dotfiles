{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    firefox
    obsidian
    signal-desktop
    blender
    qbittorrent
    discord
    mpv
    spotify
    onlyoffice-bin
    zotero
    krita
    freecad
    eog
    unrar
    ytdownloader
  ];

  # Firefox configuration (optional)
  programs.firefox = {
    enable = true;
    # You can add profiles and settings here
  };

  # MPV configuration (optional)
  programs.mpv = {
    enable = true;
    config = {
      hwdec = "auto";
      vo = "gpu";
    };
  };

  # Set kitty as default terminal for GNOME
  dconf.settings = {
    "org/gnome/desktop/applications/terminal" = {
      exec = "kitty";
      exec-arg = "-e";
    };
  };
}
