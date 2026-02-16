# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./cachix.nix
    # ./storage.nix
    # ./backup-disko.nix
    inputs.sops-nix.nixosModules.sops
    ../../modules/common.nix
    ../../modules/virtualization.nix
    ../../modules/tailscale.nix
  ];

  # Configure Tailscale exit node (DigitalOcean)
  services.tailscale.exitNode = "100.110.16.6";

  hardware.graphics = {
    enable = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  services.switcherooControl.enable = true;

  systemd.sleep.extraConfig = ''
    AllowHibernation=no
    AllowSuspendThenHibernate=no
    AllowHybridSleep=no
  '';

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

  boot.kernelPackages = pkgs.linuxPackages;

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/cd67d0ba-0e7a-4308-9bb9-1be2f9a07e17";
    preLVM = true;
    allowDiscards = true;
  };

  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  boot.kernelParams = [ "nvidia-drm.modeset=1" ];

  services.gnome.gnome-keyring.enable = true;
  security.pam.services.gdm.enableGnomeKeyring = true;

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

  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  services.libinput = {
    enable = true;
    mouse = {
      transformationMatrix = "1.0 0 0 0 1.0 0 0 0 0.5";
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
    noto-fonts
    noto-fonts-color-emoji
    corefonts
    (nerd-fonts.fira-code)
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
      "-L" # Print build logs to journald
    ];
    dates = "04:00";
    randomizedDelaySec = "45min";
    allowReboot = false;
  };

  services.udev.packages = [ pkgs.gnome-settings-daemon ];

  services.udev.extraRules = ''
    ENV{ID_FS_UUID}=="5f6f11fc-59c7-4a58-ad0b-c60e8674a469", ENV{DEVNAME}=="/dev/sdc", ENV{UDISKS_IGNORE}="1"
    ENV{ID_PATH}=="pci-0000:01:00.0", TAG+="mutter-device-preferred-primary"
    '';

  environment.systemPackages = with pkgs; [
    vim
    wget
    gnomeExtensions.appindicator
    wineWowPackages.stable
    winetricks
    helix
    direnv
    nvidia-container-toolkit
    dosbox-staging
  ];

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];

  sops.secrets.k3s-server-token = {
    sopsFile = ../../secrets/k3s/secrets.yaml;
    mode = "0400";
    owner = "root";
  };

  services.k3s.tokenFile = config.sops.secrets.k3s-server-token.path;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?
}
