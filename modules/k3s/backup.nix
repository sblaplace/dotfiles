{ config, pkgs, lib, ... }:

{
  # Automated etcd backups
  systemd.services.k3s-backup = {
    description = "Backup k3s cluster state";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
    };
    script = ''
      BACKUP_DIR="/mnt/backup/cluster-state/$(date +%Y-%m-%d_%H-%M-%S)"
      mkdir -p "$BACKUP_DIR"
      
      # Backup etcd snapshot
      ${pkgs.k3s}/bin/k3s etcd-snapshot save --name backup-$(date +%Y%m%d-%H%M%S)
      cp -a /var/lib/rancher/k3s/server/db/snapshots/* "$BACKUP_DIR/"
      
      # Backup all k8s resources
      ${pkgs.kubectl}/bin/kubectl get all --all-namespaces -o yaml > "$BACKUP_DIR/all-resources.yaml"
      ${pkgs.kubectl}/bin/kubectl get pv,pvc --all-namespaces -o yaml > "$BACKUP_DIR/pvs.yaml"
      
      # Backup Longhorn volumes metadata
      ${pkgs.kubectl}/bin/kubectl get volumes.longhorn.io -n longhorn-system -o yaml > "$BACKUP_DIR/longhorn-volumes.yaml"
      
      echo "Backup completed to $BACKUP_DIR"
    '';
  };

  systemd.timers.k3s-backup = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };

  # Off-site backups with Restic
  services.restic.backups.cluster = {
    paths = [
      "/mnt/backup/cluster-state"
      "/mnt/backup/k8s-pvs"
    ];
    
    repository = "s3:s3.amazonaws.com/your-bucket/cluster-backups";
    # Or use Backblaze B2, Wasabi, etc.
    # repository = "b2:bucket-name:path";
    
    passwordFile = config.sops.secrets.restic-password.path;
    
    environmentFile = config.sops.secrets.restic-env.path;
    # Contains AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
    
    timerConfig = {
      OnCalendar = "02:00";  # 2 AM daily
    };
    
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 4"
      "--keep-monthly 6"
      "--keep-yearly 3"
    ];
  };
}