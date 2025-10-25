{ config, pkgs, lib, ... }:

{
  # LUKS encryption for your backup drives
  boot.initrd.luks.devices = {
    backup1 = {
      device = "/dev/disk/by-uuid/YOUR-DISK1-UUID";  # Find with lsblk -f
      allowDiscards = true;
      bypassWorkqueues = true;  # Better SSD performance
    };
    backup2 = {
      device = "/dev/disk/by-uuid/YOUR-DISK2-UUID";
      allowDiscards = true;
      bypassWorkqueues = true;
    };
  };

  # BTRFS filesystem
  fileSystems."/mnt/backup" = {
    device = "/dev/mapper/backup1";
    fsType = "btrfs";
    options = [
      "compress=zstd:3"      # Good compression/speed balance
      "noatime"              # Better performance
      "space_cache=v2"       # Better free space tracking
      "autodefrag"           # Automatic defragmentation
    ];
  };

  # Add second device to RAID1
  systemd.services.btrfs-raid-setup = {
    description = "Add second device to BTRFS RAID1";
    after = [ "local-fs.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      # Check if already in RAID1
      if ! ${pkgs.btrfs-progs}/bin/btrfs device stats /mnt/backup | grep -q backup2; then
        echo "Adding backup2 to RAID1..."
        ${pkgs.btrfs-progs}/bin/btrfs device add /dev/mapper/backup2 /mnt/backup
        ${pkgs.btrfs-progs}/bin/btrfs balance start -dconvert=raid1 -mconvert=raid1 /mnt/backup
      fi
    '';
  };

  # Automated snapshots with btrbk
  services.btrbk = {
    instances.backup = {
      onCalendar = "hourly";
      settings = {
        timestamp_format = "long";
        preserve_day_of_week = "monday";
        preserve_hour_of_day = "23";
        
        # Retention policy
        snapshot_preserve = "48h 30d 12m";
        snapshot_preserve_min = "2d";
        
        volume."/mnt/backup" = {
          snapshot_dir = ".snapshots";
          
          subvolume = {
            "k8s-pvs" = {
              snapshot_create = "always";
            };
            "longhorn" = {
              snapshot_create = "always";
            };
            "cluster-state" = {
              snapshot_create = "always";
            };
          };
        };
      };
    };
  };

  # Create subvolumes
  systemd.tmpfiles.rules = [
    "d /mnt/backup/k8s-pvs 0755 root root -"
    "d /mnt/backup/longhorn 0755 root root -"
    "d /mnt/backup/cluster-state 0755 root root -"
    "d /mnt/backup/.snapshots 0755 root root -"
  ];

  # Install tools
  environment.systemPackages = with pkgs; [
    btrfs-progs
    btrbk
    restic  # For off-site backups
  ];
}