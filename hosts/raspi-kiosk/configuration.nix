{ config, pkgs, lib, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/common.nix
    ../../modules/hardware/raspberry-pi.nix
  ];

  networking.hostName = "raspi-kiosk";

  # Minimal install - no k3s
  # Just enough to run a browser in kiosk mode

  # Auto-login and start kiosk
  services.xserver = {
    enable = true;
    displayManager = {
      lightdm = {
        enable = true;
        autoLogin = {
          enable = true;
          user = "kiosk";
        };
      };
      defaultSession = "none+i3";
    };
    
    windowManager.i3 = {
      enable = true;
      extraPackages = with pkgs; [ ];
    };

    # Disable screen blanking
    serverFlagsSection = ''
      Option "BlankTime" "0"
      Option "StandbyTime" "0"
      Option "SuspendTime" "0"
      Option "OffTime" "0"
    '';
  };

  # Kiosk user
  users.users.kiosk = {
    isNormalUser = true;
    extraGroups = [ "video" ];
  };

  # Auto-start Chromium in kiosk mode
  systemd.user.services.grafana-kiosk = {
    description = "Grafana Kiosk Display";
    wantedBy = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = toString (pkgs.writeShellScript "kiosk-start" ''
        # Wait for X to be ready
        sleep 5
        
        # Hide cursor after 3 seconds of inactivity
        ${pkgs.unclutter-xfixes}/bin/unclutter --timeout 3 &
        
        # Start Chromium in kiosk mode
        ${pkgs.chromium}/bin/chromium \
          --kiosk \
          --noerrdialogs \
          --disable-infobars \
          --no-first-run \
          --disable-session-crashed-bubble \
          --disable-translate \
          --start-fullscreen \
          --window-position=0,0 \
          "http://neovenezia.local:3000/playlists/play/1?kiosk"
      '');
      Restart = "always";
      RestartSec = "10s";
    };
  };

  # i3 config for kiosk user
  home-manager.users.kiosk = {
    xsession.windowManager.i3 = {
      enable = true;
      config = {
        modifier = "Mod4";
        startup = [
          { command = "systemctl --user start grafana-kiosk"; }
        ];
        window.commands = [
          {
            criteria = { class = "^Chromium$"; };
            command = "fullscreen enable, border none";
          }
        ];
      };
    };
  };

  # Disable power management
  powerManagement.enable = false;
  services.logind.lidSwitch = "ignore";

  # Install packages
  environment.systemPackages = with pkgs; [
    chromium
    unclutter-xfixes
  ];
}