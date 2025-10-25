{ config, pkgs, lib, ... }:

{
  # Local Prometheus for system metrics (outside k8s)
  services.prometheus = {
    enable = true;
    port = 9090;
    
    exporters = {
      node = {
        enable = true;
        enabledCollectors = [
          "systemd"
          "processes"
          "cpu"
          "diskstats"
          "filesystem"
          "loadavg"
          "meminfo"
          "netdev"
          "stat"
        ];
      };

      # NVIDIA GPU metrics
      nvidia = {
        enable = config.hardware.nvidia.modesetting.enable or false;
      };
    };

    scrapeConfigs = [
      {
        job_name = "neovenezia";
        static_configs = [{
          targets = [ "localhost:9100" ];
          labels = {
            host = "neovenezia";
            role = "control-plane";
          };
        }];
      }
      {
        job_name = "nvidia-gpu";
        static_configs = [{
          targets = [ "localhost:9445" ];
        }];
      }
    ];
  };

  # BTRFS exporter
  systemd.services.btrfs-exporter = {
    description = "BTRFS Prometheus Exporter";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.python3.pkgs.prometheus-client}/bin/python ${./btrfs-exporter.py}";
      Restart = "always";
    };
  };

  # Expose Grafana
  services.grafana = {
    enable = true;
    settings = {
      server = {
        http_addr = "0.0.0.0";
        http_port = 3000;
        domain = "neovenezia.local";
        custom_css = pkgs.writeText "grafana-tv.css" ''
          /* Larger fonts for TV viewing */
          body {
            font-size: 18px !important;
          }
          
          .panel-title {
            font-size: 24px !important;
            font-weight: bold !important;
          }
          
          /* Hide unnecessary UI elements in kiosk */
          .navbar,
          .sidemenu,
          .footer {
            display: none !important;
          }
          
          /* High contrast for better visibility */
          .graph-panel {
            border: 2px solid #444 !important;
          }
          
          /* Larger stat panels */
          .singlestat-panel-value {
            font-size: 72px !important;
          }
        '';
      };

      # Anonymous access for kiosk
      "auth.anonymous" = {
        enabled = true;
        org_name = "Main Org.";
        org_role = "Viewer";
      };

      # Dark theme by default
      users = {
        default_theme = "dark";
      };
    };

    provision = {
      enable = true;
      
      datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          url = "http://localhost:9090";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          url = "http://loki.monitoring.svc.cluster.local:3100";
        }
      ];
    };
  };

  networking.firewall.allowedTCPPorts = [ 3000 9090 ];

  environment.systemPackages = with pkgs; [
    grafana
    prometheus
  ];
}