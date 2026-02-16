{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;
  
  # NetworkManager dispatcher script to handle exit node based on network
  dispatcherScript = pkgs.writeShellScript "tailscale-exit-node-dispatcher" ''
    #!/bin/sh
    # NetworkManager dispatcher script for Tailscale exit node management
    # This script runs when network connections change
    
    INTERFACE="$1"
    ACTION="$2"
    
    # Only act on up/down events
    if [ "$ACTION" != "up" ] && [ "$ACTION" != "down" ]; then
        exit 0
    fi
    
    # Get the current WiFi SSID
    SSID=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2)
    
    # Home network SSIDs (space-separated list)
    HOME_SSIDS="Little Pink Houses"
    
    # Check if we're on a home network
    IS_HOME=0
    for home_ssid in $HOME_SSIDS; do
        if [ "$SSID" = "$home_ssid" ]; then
            IS_HOME=1
            break
        fi
    done
    
    # Exit node configuration
    EXIT_NODE="${cfg.exitNode}"
    
    if [ $IS_HOME -eq 1 ]; then
        # On home network - disable exit node
        logger -t tailscale-dispatcher "On home network ($SSID), disabling exit node"
        ${pkgs.tailscale}/bin/tailscale up --exit-node= --accept-routes
    elif [ -n "$SSID" ] && [ -n "$EXIT_NODE" ]; then
        # On external WiFi network - enable exit node
        logger -t tailscale-dispatcher "On external network ($SSID), enabling exit node $EXIT_NODE"
        ${pkgs.tailscale}/bin/tailscale up --exit-node=$EXIT_NODE --accept-routes
    elif [ -z "$SSID" ] && [ "$ACTION" = "up" ] && [ -n "$EXIT_NODE" ]; then
        # Wired connection - enable exit node
        logger -t tailscale-dispatcher "On wired network, enabling exit node $EXIT_NODE"
        ${pkgs.tailscale}/bin/tailscale up --exit-node=$EXIT_NODE --accept-routes
    fi
  '';
in
{
  config = lib.mkIf (cfg.enable && cfg.exitNode != null && cfg.exitNode != "") {
    # Install NetworkManager dispatcher script
    networking.networkmanager.dispatcherScripts = [
      {
        source = dispatcherScript;
        type = "basic";
      }
    ];

    # Override the systemd service to NOT auto-enable exit node on boot
    # The dispatcher will handle it based on network
    systemd.services.tailscale-exit-node = lib.mkForce {
      description = "Configure Tailscale exit node based on network";
      after = [ "tailscale.service" "NetworkManager.service" ];
      wants = [ "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Just bring up Tailscale without exit node
        # Let the dispatcher handle exit node configuration
        ExecStart = "${pkgs.tailscale}/bin/tailscale up --accept-routes";
      };
    };
  };
}
