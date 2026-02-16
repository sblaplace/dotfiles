{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;
  
  # NetworkManager dispatcher script to handle LAN awareness
  lanAwarenessScript = pkgs.writeShellScript "tailscale-lan-awareness" ''
    INTERFACE=$1
    ACTION=$2

    # Exit if not wifi
    if [ "$INTERFACE" != "wlan0" ] && [ "$INTERFACE" != "wlp1s0" ] && [ "$INTERFACE" != "wlp2s0" ]; then
      exit 0
    fi

    SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    HOME_SSID="Little Pink Houses"

    case "$ACTION" in
      up|vpn-up)
        if [ "$SSID" = "$HOME_SSID" ]; then
          # On Home LAN: Disable exit node
          ${pkgs.tailscale}/bin/tailscale up --exit-node= --accept-routes
        else
          # Not on Home LAN: Enable exit node if configured
          if [ -n "${cfg.exitNode}" ]; then
            ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes
          fi
        fi
        ;;
      down|vpn-down)
        # If we lose wifi but have another connection, ensure exit node is back on if configured
        if [ -n "${cfg.exitNode}" ]; then
          ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes
        fi
        ;;
    esac
  '';
in
{
  options.services.tailscale = {
    exitNode = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Tailscale exit node to automatically connect to on boot or when leaving LAN.
        Can be specified as a node name or tailnet IP (e.g. "100.110.16.6").
      '';
    };
  };

  config = {
    services.tailscale.enable = true;

    networking.firewall = {
      allowedUDPPorts = [ cfg.port ];
      trustedInterfaces = [ "tailscale0" ];
    };

    environment.systemPackages = with pkgs; [
      tailscale
    ];

    # Register the dispatcher script
    networking.networkmanager.dispatcherScripts = [
      {
        source = lanAwarenessScript;
        type = "basic";
      }
    ];

    # Initial connection on boot
    systemd.services.tailscale-exit-node = lib.mkIf (cfg.exitNode != null && cfg.exitNode != "") {
      description = "Configure Tailscale exit node";
      after = [ "tailscale.service" "network-online.target" ];
      wants = [ "tailscale.service" "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes";
      };
    };
  };
}
