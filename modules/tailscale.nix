{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.tailscale;

  # NetworkManager dispatcher script to handle LAN awareness
  # Runs in background so NM is never blocked if tailscale isn't ready
  lanAwarenessScript = pkgs.writeShellScript "tailscale-lan-awareness" ''
    INTERFACE=$1
    ACTION=$2

    # Exit if not a WiFi interface
    case "$INTERFACE" in
      wlan*|wlp*) ;;
      *) exit 0 ;;
    esac

    # Background the heavy work so NM activation never stalls
    (
      sleep 2
      SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
      HOME_SSID="Little Pink Houses"

      case "$ACTION" in
        up|vpn-up)
          if [ "$SSID" = "$HOME_SSID" ]; then
            ${pkgs.tailscale}/bin/tailscale up --exit-node= --accept-routes --accept-dns=false 2>/dev/null || true
          else
            if [ -n "${cfg.exitNode}" ]; then
              ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes --accept-dns=false 2>/dev/null || true
            fi
          fi
          ;;
        down|vpn-down)
          if [ -n "${cfg.exitNode}" ]; then
            ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes --accept-dns=false 2>/dev/null || true
          fi
          ;;
      esac
    ) &
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
      after = [
        "tailscale.service"
        "network-online.target"
      ];
      wants = [
        "tailscale.service"
        "network-online.target"
      ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes --accept-dns=false";
      };
    };
  };
}
