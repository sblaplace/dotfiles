{
  config,
  pkgs,
  inputs,
  lib,
  ...
}:

{
  # Note: sops-nix is managed at the system level for NixOS machines.
  # Home Manager sops-nix is not imported here because it tries to restart
  # a user systemd service that doesn't exist when HM is used as a NixOS module.
  # Secrets are still decrypted to /run/secrets/ by system-level sops-nix.

  # Activation scripts to copy secrets from /run/secrets/ to proper locations
  home.activation.sshKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p /home/laplace/.ssh
    $DRY_RUN_CMD chmod 700 /home/laplace/.ssh
    if [ -r /run/secrets/ssh_id_ed25519 ]; then
      $DRY_RUN_CMD cp /run/secrets/ssh_id_ed25519 /home/laplace/.ssh/id_ed25519
      $DRY_RUN_CMD chmod 600 /home/laplace/.ssh/id_ed25519
    fi
    if [ -r /run/secrets/ssh_id_ed25519_pub ]; then
      $DRY_RUN_CMD cp /run/secrets/ssh_id_ed25519_pub /home/laplace/.ssh/id_ed25519.pub
      $DRY_RUN_CMD chmod 644 /home/laplace/.ssh/id_ed25519.pub
    fi
    if [ -r /run/secrets/ssh_id_runpod_storagebox ]; then
      $DRY_RUN_CMD cp /run/secrets/ssh_id_runpod_storagebox /home/laplace/.ssh/id_runpod_storagebox
      $DRY_RUN_CMD chmod 600 /home/laplace/.ssh/id_runpod_storagebox
    fi
    if [ -r /run/secrets/ssh_id_runpod_storagebox_pub ]; then
      $DRY_RUN_CMD cp /run/secrets/ssh_id_runpod_storagebox_pub /home/laplace/.ssh/id_runpod_storagebox.pub
      $DRY_RUN_CMD chmod 644 /home/laplace/.ssh/id_runpod_storagebox.pub
    fi
  '';

  home.activation.awsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p /home/laplace/.aws
    if [ -r /run/secrets/aws_credentials ]; then
      $DRY_RUN_CMD cp /run/secrets/aws_credentials /home/laplace/.aws/credentials
      $DRY_RUN_CMD chmod 600 /home/laplace/.aws/credentials
    fi
    if [ -r /run/secrets/aws_config ]; then
      $DRY_RUN_CMD cp /run/secrets/aws_config /home/laplace/.aws/config
      $DRY_RUN_CMD chmod 600 /home/laplace/.aws/config
    fi
  '';

  home.activation.vastaiConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p /home/laplace/.config/vastai
    if [ -r /run/secrets/vastai_api_key ]; then
      $DRY_RUN_CMD cp /run/secrets/vastai_api_key /home/laplace/.config/vastai/vast_api_key
      $DRY_RUN_CMD chmod 600 /home/laplace/.config/vastai/vast_api_key
    fi
  '';

  home.activation.mithrilConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p /home/laplace/.config/mithril
    if [ -r /run/secrets/mithril_api_key ]; then
      $DRY_RUN_CMD printf "fkey: %s\n" "$(cat /run/secrets/mithril_api_key)" > /home/laplace/.config/mithril/config.yaml
      $DRY_RUN_CMD chmod 600 /home/laplace/.config/mithril/config.yaml
    else
      echo "Warning: mithril_api_key secret not available"
    fi
  '';

  home.activation.doctlConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD mkdir -p /home/laplace/.config/doctl
    if [ -r /run/secrets/doctl_access_token ]; then
      $DRY_RUN_CMD printf "access-token: %s\n" "$(cat /run/secrets/doctl_access_token)" > /home/laplace/.config/doctl/config.yaml
      $DRY_RUN_CMD chmod 600 /home/laplace/.config/doctl/config.yaml
    else
      echo "Warning: doctl_access_token secret not available"
    fi
  '';
}
