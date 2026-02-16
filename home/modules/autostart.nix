{ config, pkgs, lib, ... }:

{
  systemd.user.services = {
    # Background services
    discord = {
      Unit = {
        Description = "Discord";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "idle";  # Waits until active jobs are dispatched
        ExecStart = "${pkgs.discord}/bin/discord";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    qbittorrent = {
      Unit = {
        Description = "Qbittorrent";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "idle";  # Waits until active jobs are dispatched
        ExecStart = "${pkgs.qbittorrent}/bin/qbittorrent";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    steam = {
      Unit = {
        Description = "Steam";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "idle";  # Waits until active jobs are dispatched
        ExecStart = "${pkgs.steam}/bin/steam";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    obsidian = {
      Unit = {
        Description = "Obsidian";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "idle";  # Waits until active jobs are dispatched
        ExecStart = "${pkgs.obsidian}/bin/obsidian";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };

    vscode = {
      Unit = {
        Description = "VScode";
        After = [ "graphical-session.target" ];
      };
      Service = {
        Type = "idle";  # Waits until active jobs are dispatched
        ExecStart = "${pkgs.vscode}/bin/code";
        RemainAfterExit = true;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
