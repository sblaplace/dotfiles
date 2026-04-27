{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./cachix.nix
    # ./storage.nix
    # ./backup-disko.nix
    inputs.sops-nix.nixosModules.sops
    ../../modules/common.nix
    ../../modules/desktop.nix
    ../../modules/virtualization.nix
    ../../modules/tailscale.nix
    ../../modules/lute.nix
    ../../modules/hardware/nvidia.nix
    ../../modules/hardware/cuda.nix
    ../../modules/hardware/mouse.nix

  ];

  # Configure Tailscale exit node (DigitalOcean)
  services.tailscale.exitNode = "100.110.16.6";

  # Enable Lute language learning server
  services.lute = {
    enable = true;
    port = 5006;
    openFirewall = true;
  };

  hardware.graphics = {
    enable = true;
  };

  services.switcherooControl.enable = true;

  home-manager.backupFileExtension = "backup";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 2;

  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # Pinned to LTS kernel — legacy NVIDIA drivers have build issues
  # with latest kernels. Keep pinned until driver situation is resolved.
  # Also pin nvidia_x11 so userland libs match the kernel module (legacy_580).
  boot.kernelPackages = pkgs.linuxPackages_6_12.extend (self: super: {
    nvidia_x11 = super.nvidiaPackages.legacy_580;
  });

  # Work around ath10k firmware hangs common on mesh WiFi with band steering
  boot.extraModprobeConfig = ''
    options ath10k_core skip_otp=y fw_diag_log=0
    options ath10k_pci irq_mode=1
  '';

  # Unlock the regulatory domain to allow overriding EEPROM restrictions
  networking.wireless.athUserRegulatoryDomain = true;

  # iwd-specific tuning for mesh roaming stability
  networking.wireless.iwd.settings = {
    General = {
      # Use per-network MAC addresses to avoid confusing mesh APs during roaming
      AddressRandomization = "network";
      # Default is -70. Lowering the threshold makes it less aggressive about 
      # jumping between APs, which can help if the mesh is constantly steering.
      RoamThreshold = -76;
      RoamThreshold5G = -72;
    };
    Network = {
      # Disable 802.11r (Fast Transition) — often unstable on ath10k/QCA9377
      # firmware and a common cause of roaming timeouts (Reason 2).
      EnableFastTransition = false;
    };
  };

  # Explicitly disable mac80211 power save for qca9377 — NM's powersave=false
  # doesn't always reach the firmware on this card. Also set regdomain.
  systemd.services.disable-wifi-powersave = {
    description = "Disable WiFi power save and set regdomain";
    after = [ "network.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = [
        "${pkgs.bash}/bin/bash -c 'IFACE=$(ls /sys/class/net | grep -E \"^(wlp|wlan)\" | head -n1); [ -n \"$IFACE\" ] && ${pkgs.iw}/bin/iw dev \"$IFACE\" set power_save off && ${pkgs.iw}/bin/iw reg set US'"
      ];
    };
  };

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/cd67d0ba-0e7a-4308-9bb9-1be2f9a07e17";
    preLVM = true;
    allowDiscards = true;
  };

  # neovenezia-specific mouse sensitivity
  networking.hostName = "neovenezia";
  networking.wireless.iwd.enable = true;
  networking.networkmanager = {
    enable = true;
    wifi = {
      backend = "iwd";
      powersave = false;
      scanRandMacAddress = false;
    };
    # Ignore IPv6 for now as it's causing "Address unreachable" errors
    # and we lack a valid default route for it.
    connectionConfig = {
      "ipv6.method" = "ignore";
    };
  };

  hardware.enableRedistributableFirmware = true;

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "ter-v16n";
    packages = [ pkgs.terminus_font ];
    useXkbConfig = true;
  };

  programs.nix-ld.libraries = with pkgs; [
    icu
    dotnet-sdk_8
    stdenv.cc.cc.lib
    zlib
    config.boot.kernelPackages.nvidia_x11
  ];
  programs.nix-ld.enable = true;
  programs.appimage = {
    enable = true;
    binfmt = true;
    package = pkgs.appimage-run.override {
      extraPkgs =
        pkgs: with pkgs; [
          icu
          libxcrypt-legacy
        ];
    };
  };

  users.users.laplace = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
    shell = pkgs.fish;
  };

  virtualisation.docker = {
    enable = true;
  };

  fonts.packages = with pkgs; [
    crimson
    gyre-fonts
  ];

  programs.fish.interactiveShellInit = ''
    starship init fish | source
  '';

  services.qbittorrent = {
    enable = true;
    openFirewall = true;
  };

  networking.firewall.allowedTCPPorts = [
    57621
    8000
  ];
  networking.firewall.allowedUDPPorts = [ 5353 ];

  programs.git = {
    enable = true;
    config = {
      user = {
        name = "Sarah Laplace";
        email = "sblaplace@gmail.com";
      };

      init.defaultBranch = "main";
    };
    lfs.enable = true;
  };

  programs.steam.extraCompatPackages = [ pkgs.proton-ge-bin ];

  programs.fish.enable = true;

  nixpkgs.config.allowUnfree = true;

  # sm_61 (Pascal / GTX 1080 Ti) CUDA capability — no overlay needed,
  # just set the capability so nixpkgs builds CUDA packages correctly.

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraPackages = [ pkgs.proton-ge-bin ];
  };

  networking.firewall.checkReversePath = false;

  system.autoUpgrade = {
    enable = true;
    flake = "github:sblaplace/dotfiles";
    flags = [
      "-L"
      "--recreate-lock-file"
      "--commit-lock-file"
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
    persistent = true;
  };

  services.udev.extraRules = ''
    ENV{ID_FS_UUID}=="5f6f11fc-59c7-4a58-ad0b-c60e8674a469", ENV{DEVNAME}=="/dev/sdc", ENV{UDISKS_IGNORE}="1"
    ENV{ID_PATH}=="pci-0000:01:00.0", TAG+="mutter-device-preferred-primary"
  '';

  # 1. Ollama backend with CUDA (GTX 1080 Ti)

  # 2. Open WebUI frontend
  services.open-webui = {
    enable = true;
    port = 8082;
    openFirewall = true;
    host = "0.0.0.0";
    environment = {
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      ANONYMOUS_USAGE_STATS = "false";
      GLOBAL_LOG_LEVEL = "DEBUG";
    };
  };

  systemd.services.open-webui.path = with pkgs; [
    bash
    curl
    coreutils
    nodejs
    (python3.withPackages (
      ps: with ps; [
        requests
        aiohttp
        beautifulsoup4
        pydantic
      ]
    ))
  ];

  environment.systemPackages = with pkgs; [
    vim
    wget
    wineWow64Packages.stable
    winetricks
    helix
    direnv
    nvidia-container-toolkit
    dosbox-staging
    typst
    doctl
    wirelesstools
    iw
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.k3s-server-token = {
    sopsFile = ../../secrets/k3s/secrets.yaml;
    mode = "0400";
    owner = "root";
  };

  # User secrets - written to /run/secrets/ and symlinked/copied by activation scripts
  sops.secrets.ssh_id_ed25519 = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "ssh_id_ed25519";
    mode = "0600";
    owner = "laplace";
  };
  sops.secrets.ssh_id_ed25519_pub = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "ssh_id_ed25519_pub";
    mode = "0644";
    owner = "laplace";
  };
  sops.secrets.ssh_id_runpod_storagebox = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "ssh_id_runpod_storagebox";
    mode = "0600";
    owner = "laplace";
  };
  sops.secrets.ssh_id_runpod_storagebox_pub = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "ssh_id_runpod_storagebox_pub";
    mode = "0644";
    owner = "laplace";
  };
  sops.secrets.aws_credentials = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "aws_credentials_file";
    mode = "0600";
    owner = "laplace";
  };
  sops.secrets.aws_config = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "aws_config_file";
    mode = "0600";
    owner = "laplace";
  };
  sops.secrets.vastai_api_key = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "vastai_api_key";
    mode = "0600";
    owner = "laplace";
  };
  sops.secrets.mithril_api_key = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "mithril_api_key";
    mode = "0600";
    owner = "laplace";
  };
  sops.secrets.doctl_access_token = {
    sopsFile = ../../secrets/user/secrets.yaml;
    key = "doctl_access_token";
    mode = "0600";
    owner = "laplace";
  };

  services.k3s.tokenFile = config.sops.secrets.k3s-server-token.path;

  services.openssh.enable = true;

  system.stateVersion = "25.05";
}
