{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hyprland.nix
  ];

  home.packages = with pkgs; [
    obsidian
    signal-desktop
    blender
    qbittorrent
    (
      (discord.override {
        withOpenASAR = true;
        withVencord = true;
      })
    )
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
    lycheeslicer
    kdePackages.kdenlive
    shotcut
    awscli2
    restic
    chromium
  ];

  programs.firefox = {
    enable = true;
    # Apply memory optimizations for Firefox/Zen
    # These reduce RAM/VRAM usage by controlling tab behavior
    policies = {
      # Enable memory pressure handling
      Performance = {
        MemoryPressure = true;
      };
    };
    profiles.default = {
      settings = {
        # Unload tabs when memory is low
        "browser.tabs.unloadOnLowMemory" = true;
        # Reduce inactive tab unload time (default is usually much higher)
        "browser.tabs.min_inactive_duration_before_unload" = 300; # 5 minutes
        # Disable smooth scrolling (reduces GPU load slightly)
        "general.smoothScroll" = false;
        # Limit content process count (reduces memory)
        "dom.ipc.processCount" = 4;
        # Disable hardware acceleration to save VRAM
        # Note: This moves rendering load to CPU. Toggle in Settings -> Performance if needed.
        "layers.acceleration.disabled" = true;
      };
    };
  };

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

  xdg.desktopEntries.lycheeslicer = {
    name = "LycheeSlicer";
    exec = "${lib.getExe pkgs.lycheeslicer} %u";
    type = "Application";
    terminal = false;
    mimeType = [ "x-scheme-handler/lycheeslicer" ];
    categories = [ "Graphics" ];
  };
}
