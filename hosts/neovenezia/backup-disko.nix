{ ... }:
{
  disko.devices = {
    disk = {
      backup1 = {
        type = "disk";
        device = "/dev/sda";  # Adjust to your actual devices
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "backup1";
                settings.allowDiscards = true;
                passwordFile = "/tmp/backup-secret.key";
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" "-L backup-pool" ];
                  subvolumes = {
                    "/k8s-pvs" = {
                      mountpoint = "/mnt/backup/k8s-pvs";
                    };
                    "/longhorn" = {
                      mountpoint = "/mnt/backup/longhorn";
                    };
                    "/cluster-state" = {
                      mountpoint = "/mnt/backup/cluster-state";
                    };
                  };
                };
              };
            };
          };
        };
      };
      
      backup2 = {
        type = "disk";
        device = "/dev/sdb";
        content = {
          type = "gpt";
          partitions = {
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "backup2";
                settings.allowDiscards = true;
                passwordFile = "/tmp/backup-secret.key";
                # Will be added to RAID1 by systemd service
              };
            };
          };
        };
      };
    };
  };
}