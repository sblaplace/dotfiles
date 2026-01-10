{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./autostart.nix
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
    freecad
    kicad
    gum
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
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
      hwdec = "auto-safe";
      vo = "gpu";
    };
  };

  xdg.terminal-exec = {
    enable = true;
    settings = {
      GNOME = [ "kitty.desktop" ];
    };
  };
}
