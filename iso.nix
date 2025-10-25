{ pkgs, modulesPath, ... }:
{
  imports = [ "${modulesPath}/installer/cd-dvd/installation-cd-minimal.nix" ];

  # Enable SSH out of the box
  services.openssh.enable = true;
  services.openssh.settings.PermitRootLogin = "yes";
  
  # Include your SSH keys
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIgMOvsGafYDZNWv2lP1WobD80vhYbTUiMIBkoeIpyV+ sblaplace@gmail.com"
  ];

  # Auto-start SSH
  systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
  
  # Include nixos-anywhere and disko in the ISO
  environment.systemPackages = with pkgs; [
    git
    vim
  ];
}