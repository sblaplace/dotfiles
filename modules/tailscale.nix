{ config, pkgs, ... }:

{
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
    allowedUDPPorts = [ config.services.tailscale.port ];

    # Trust Tailscale interface (so services you explicitly listen on can be reached via tailscale0)
    trustedInterfaces = [ "tailscale0" ];
  };

  # Add tailscale CLI to system packages
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Automatically connect to DO exit node on boot
  # To configure: Set the exit node hostname in your host-specific config with:
  #   services.tailscale.exitNode = "your-do-hostname";
  systemd.services.tailscale-exit-node = {
    description = "Configure Tailscale exit node";
    after = [ "tailscale.service" ];
    wants = [ "tailscale.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # Use --accept-routes to also receive subnet routes from exit node if configured
      ExecStart = "${pkgs.tailscale}/bin/tailscale up --exit-node=\${EXIT_NODE} --accept-routes";
    };
    # Set EXIT_NODE environment variable from host config
    environment.EXIT_NODE = 
      if config.services.tailscale ? exitNode && config.services.tailscale.exitNode != null
      then config.services.tailscale.exitNode
      else "";
    # Only start if EXIT_NODE is configured
    unitConfig.ConditionPathExists = 
      pkgs.writeText "tailscale-exit-node-check" 
        (if config.services.tailscale ? exitNode && config.services.tailscale.exitNode != null && config.services.tailscale.exitNode != ""
         then "configured"
         else "");
  };
}
