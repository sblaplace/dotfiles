{ config, pkgs, lib, ... }:

{
  wayland.windowManager.hyprland = {
    enable = true;
    settings = {
      monitor = ",preferred,auto,1";

      general = {
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        layout = "dwindle";
      };

      decoration = {
        rounding = 8;
        blur.enabled = true;
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        sensitivity = 0;
      };

      "$mod" = "SUPER";

      bind = [
        "$mod, Return, exec, kitty"
        "$mod, Q, killactive"
        "$mod, M, exit"
        "$mod, F, fullscreen"
        "$mod, Space, togglefloating"
        "$mod, D, exec, rofi -show drun"
        "$mod, S, exec, grim -g \"$(slurp)\" ~/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];

      exec-once = [
        "waybar"
        "mako"
        "hyprpaper"
        "discord --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "obsidian --enable-features=UseOzonePlatform --ozone-platform=wayland"
        "qbittorrent"
      ];
    };
  };

  programs.waybar = {
    enable = true;
    settings = [{
      layer = "top";
      position = "top";
      modules-left = [ "hyprland/workspaces" "hyprland/window" ];
      modules-center = [ "clock" ];
      modules-right = [ "pulseaudio" "network" "cpu" "memory" "tray" ];
      clock = { format = "{:%a %b %d  %H:%M}"; };
      cpu = { format = " {usage}%"; };
      memory = { format = " {percentage}%"; };
      network = {
        format-wifi = " {signalStrength}%";
        format-ethernet = " connected";
        format-disconnected = "⚠ disconnected";
      };
      pulseaudio = { format = " {volume}%"; };
    }];
  };

  home.packages = with pkgs; [
    rofi-wayland
    mako
    hyprpaper
    wl-clipboard
    grim
    slurp
    brightnessctl
    playerctl
    libnotify
  ];
}
