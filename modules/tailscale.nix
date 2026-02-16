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

  # After enabling, authenticate and select the DO exit node:
  #   sudo tailscale up --exit-node=<your-DO-exit-node>
  #
  # To make exit node persistent across reboots, you can add a systemd service like:
  # systemd.services.tailscale-exit-node = {
  #   description = "Configure Tailscale exit node";
  #   after = [ "tailscale.service" ];
  #   wants = [ "tailscale.service" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     Type = "oneshot";
  #     ExecStart = "${pkgs.tailscale}/bin/tailscale up --exit-node=<your-DO-exit-node>";
  #   };
  # };
}
