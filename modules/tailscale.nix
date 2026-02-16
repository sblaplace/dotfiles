{ config, pkgs, ... }:

{
  # Enable Tailscale service
  services.tailscale.enable = true;

  # Configure firewall for Tailscale
  networking.firewall = {
    # Tailscale uses loose reverse path filtering
    checkReversePath = "loose";
    # Allow Tailscale UDP port
    allowedUDPPorts = [ config.services.tailscale.port ];
    # Trust Tailscale interface
    trustedInterfaces = [ "tailscale0" ];
  };

  # Add tailscale CLI to system packages
  environment.systemPackages = with pkgs; [
    tailscale
  ];

  # Note: After enabling, authenticate with:
  #   sudo tailscale up --exit-node=<your-DO-exit-node>
  # 
  # To make exit node persistent across reboots, you can add a systemd service:
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
