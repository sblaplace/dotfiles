{ config, pkgs, lib, ... }:

{
  # NFS server for Longhorn backups
  services.nfs.server = {
    enable = true;
    exports = ''
      /mnt/backup/longhorn 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)
    '';
  };

  networking.firewall.allowedTCPPorts = [ 2049 ];  # NFS

  # Or use S3-compatible storage (MinIO)
  virtualisation.oci-containers.containers.minio = {
    image = "minio/minio:latest";
    ports = [ "9000:9000" "9001:9001" ];
    volumes = [
      "/mnt/backup/minio:/data"
    ];
    environment = {
      MINIO_ROOT_USER = "admin";
      MINIO_ROOT_PASSWORD = "changeme123";  # Use sops for this!
    };
    cmd = [ "server" "/data" "--console-address" ":9001" ];
  };
}