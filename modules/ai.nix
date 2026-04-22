{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

{
  imports = [
    inputs.comfyui-nix.nixosModules.default
  ];

  # Enable CUDA build for Pascal GPU (sm_61) support in nixpkgs
  nixpkgs.config.cudaCapabilities = [ "6.1" ];

  # Rebuild PyTorch from source with CUDA support
  # The pre-built CUDA 12.8 wheels from pytorch.org don't include sm_61 CUDA kernels
  # This overlay runs after comfyui-nix's overlay (listed first) to override the torch package
  nixpkgs.overlays = [
    inputs.comfyui-nix.overlays.default
    (final: prev: {
      python3Packages = prev.python3Packages.overrideScope (
        self: super: {
          # Rebuild PyTorch from source with sm_61 (Pascal) support
          # The pre-built CUDA 12.8 wheels from pytorch.org dropped sm_61 kernel support
          torch = super.torch.override {
            cudaSupport = true;
            cudaPackages = pkgs.cudaPackages;
            cudnnSupport = true;
            cudnnCaps = [ "8" ];
            enable64Bits = true;
          };
        }
      );
    })
  ];

  # 1. Enable Ollama Backend
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda; # Uses your NVIDIA GPU
    # listenAddress = "127.0.0.1:11434"; # Default, strictly local
  };

  # 2. Enable Open WebUI Frontend
  services.open-webui = {
    enable = true;
    port = 8082;
    openFirewall = true; # Open port 8080 in the firewall
    host = "0.0.0.0"; # Listen on all interfaces so you can access it from other devices
    environment = {
      # Allow Open WebUI to talk to Ollama
      OLLAMA_API_BASE_URL = "http://127.0.0.1:11434";
      # Helper to keep the interface clean
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

  # 3. Enable ComfyUI (Stable Diffusion GUI) with CUDA support
  services.comfyui = {
    enable = true;
    gpuSupport = "cuda";
    port = 8188;
    listenAddress = "0.0.0.0";
    enableManager = true;
    dataDir = "/var/lib/comfyui";
    openFirewall = true;
  };

  environment.systemPackages = with pkgs; [
    pkgs.comfy-ui-cuda
  ];
}
