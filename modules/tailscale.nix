{ config, lib, pkgs, ... }:

let
  cfg = config.services.tailscale;
in
{
  options.services.tailscale = {
    exitNode = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = '';
        Tailscale exit node to automatically connect to on boot.
        Can be specified as a node name or tailnet IP (e.g. "100.110.16.6").
        Set to null or empty string to disable automatic exit node connection.
      '';
    };
  };

  config = {
    # Enable Tailscale service
    services.tailscale.enable = true;

    # Configure firewall for Tailscale
    networking.firewall = {
      # NOTE: Your host config already sets `networking.firewall.checkReversePath = false;`.
      # Nix's option merging for this option doesn't allow mixing boolean + string values
      # across modules, so we do NOT set it here.
      # If you remove the host-level setting, consider setting it to "loose" (or false)
      # for best compatibility with Tailscale.

      # Allow Tailscale UDP port
      allowedUDPPorts = [ cfg.port ];

      # Trust Tailscale interface (so services you explicitly listen on can be reached via tailscale0)
      trustedInterfaces = [ "tailscale0" ];
    };

    # Add tailscale CLI to system packages
    environment.systemPackages = with pkgs; [
      tailscale
    ];

    # Automatically connect to exit node on boot (only if configured)
    systemd.services.tailscale-exit-node = lib.mkIf (cfg.exitNode != null && cfg.exitNode != "") {
      description = "Configure Tailscale exit node";
      after = [ "tailscale.service" ];
      wants = [ "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        # Use --accept-routes to receive subnet routes from exit node if configured
        ExecStart = "${pkgs.tailscale}/bin/tailscale up --exit-node=${cfg.exitNode} --accept-routes";
      };
    };
  };
}
