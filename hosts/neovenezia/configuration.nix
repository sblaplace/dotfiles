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
    ../../modules/ai.nix
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

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580;
  };

  services.switcherooControl.enable = true;

  home-manager.backupFileExtension = "backup";

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.xserver.videoDrivers = [ "nvidia" ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  nix.gc.automatic = true;
  nix.gc.dates = "weekly";

  # Pinned to LTS kernel — legacy NVIDIA drivers (570.x) have build issues
  # with latest kernels. Keep pinned until driver situation is resolved.
  boot.kernelPackages = pkgs.linuxPackages_6_12;

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/cd67d0ba-0e7a-4308-9bb9-1be2f9a07e17";
    preLVM = true;
    allowDiscards = true;
  };

  boot.initrd.kernelModules = [
    "nvidia"
    "nvidia_modeset"
    "nvidia_uvm"
    "nvidia_drm"
  ];
  boot.kernelParams = [
    "nvidia-drm.modeset=1"
    "nvidia.NVreg_EnableGpuFirmware=0"
  ];

  # neovenezia-specific mouse sensitivity
  services.libinput.mouse.transformationMatrix = "1.0 0 0 0 1.0 0 0 0 0.25";

  networking.hostName = "neovenezia";
  networking.networkmanager = {
    enable = true;
    wifi = {
      backend = "iwd";
      powersave = false;
      scanRandMacAddress = false;
    };
  };

  time.timeZone = "America/Chicago";

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  programs.nix-ld.libraries = with pkgs; [
    icu
    dotnet-sdk_8
    stdenv.cc.cc.lib
    zlib
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

  hardware.nvidia-container-toolkit.enable = true;

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
