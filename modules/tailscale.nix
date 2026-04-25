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

    case "$INTERFACE" in
      wlan*|wlp*) ;;
      *) exit 0 ;;
    esac

    # Ignore down events entirely to avoid reconfiguring during WiFi roams
    case "$ACTION" in
      down|vpn-down) exit 0 ;;
    esac

    STATE_FILE="/run/tailscale-nm-state"
    LOG_TAG="tailscale-dispatcher"
    HOME_SSID="Little Pink Houses"

    # Background the heavy work so NM activation never stalls
    (
      sleep 2

      SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)
      [ -z "$SSID" ] && exit 0

      DESIRED_STATE="away"
      [ "$SSID" = "$HOME_SSID" ] && DESIRED_STATE="home"

      LAST_STATE=$(cat "$STATE_FILE" 2>/dev/null || echo "")

      if [ "$LAST_STATE" = "$DESIRED_STATE" ]; then
        logger -t "$LOG_TAG" "SSID=$SSID state=$DESIRED_STATE already active, skipping tailscale up"
        exit 0
      fi

      logger -t "$LOG_TAG" "SSID=$SSID changing state '$LAST_STATE' -> '$DESIRED_STATE'"

      if [ "$DESIRED_STATE" = "home" ]; then
        ${pkgs.tailscale}/bin/tailscale up --exit-node= --accept-routes --accept-dns=false 2>/dev/null || true
      else
        if [ -n "${cfg.exitNode}" ]; then
          ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes --accept-dns=false 2>/dev/null || true
        fi
      fi

      echo "$DESIRED_STATE" > "$STATE_FILE"
    ) &
  '';

  # Boot script that checks SSID before applying exit node
  bootScript = pkgs.writeShellScript "tailscale-boot-exit-node" ''
    STATE_FILE="/run/tailscale-nm-state"
    HOME_SSID="Little Pink Houses"

    # Wait for NetworkManager to have WiFi state
    sleep 5

    SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes' | cut -d: -f2)

    if [ "$SSID" = "$HOME_SSID" ]; then
      logger -t "tailscale-boot" "Booting on home network ($SSID), no exit node"
      echo "home" > "$STATE_FILE"
      ${pkgs.tailscale}/bin/tailscale up --exit-node= --accept-routes --accept-dns=false 2>/dev/null || true
    else
      if [ -n "${cfg.exitNode}" ]; then
        logger -t "tailscale-boot" "Booting on external network, enabling exit node"
        echo "away" > "$STATE_FILE"
        ${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes --accept-dns=false 2>/dev/null || true
      fi
    fi
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
        ExecStart = "${bootScript}";
      };
    };
  };
}
