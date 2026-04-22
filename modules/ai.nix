{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  # Import nixos-stable for aarch64 fallback. x86_64 should never use cuda_compat
  # because it is aarch64-only (driver compat package). The nixos-unstable version
  # for CUDA 12.9 is also missing the x86_64-linux redistributable source.
  stable = inputs.nixos-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system};
  isAarch64 = pkgs.stdenv.hostPlatform.isAarch64;
in

{
  imports = [
    inputs.comfyui-nix.nixosModules.default
  ];

  # Enable CUDA build for Pascal GPU (sm_61) support in nixpkgs
  nixpkgs.config = {
    cudaCapabilities = [ "6.1" ];
    # cudnn is marked badPlatform for x86_64 in this nixpkgs version despite working
    allowUnsupportedSystem = true;
  };

  # Use pre-built PyTorch CUDA 12.6 wheels instead of 12.8.
  # PyTorch 2.10.0's CUDA 12.8 wheels dropped sm_61 (Pascal) support, but the
  # CUDA 12.6 wheels still include it. We patch comfyui-nix to use cu126 wheels.
  # We also pull cuda_compat from nixos-stable to avoid a broken local rebuild in nixos-unstable.
  nixpkgs.overlays = [
    inputs.comfyui-nix.overlays.default
    (final: prev: {
      # Patched comfyui-nix source: fixes xorg.* deprecation warnings and wheel
      # runtime-deps-check failures caused by incomplete propagatedBuildInputs.
      comfyuiNixPatched = prev.runCommand "comfyui-nix-patched" { } ''
        cp -r ${inputs.comfyui-nix} $out
        chmod -R +w $out
        # Fix xorg package set deprecation warnings
        sed -i \
          -e 's/pkgs\.xorg\.libxcb/pkgs.libxcb/g' \
          -e 's/pkgs\.xorg\.libX11/pkgs.libX11/g' \
          -e 's/pkgs\.xorg\.libXext/pkgs.libXext/g' \
          -e 's/pkgs\.xorg\.libXrender/pkgs.libXrender/g' \
          -e 's/pkgs\.xorg\.libXfixes/pkgs.libXfixes/g' \
          -e 's/pkgs\.xorg\.libXi/pkgs.libXi/g' \
          -e 's/pkgs\.xorg\.libXrandr/pkgs.libXrandr/g' \
          -e 's/pkgs\.xorg\.libXcursor/pkgs.libXcursor/g' \
          -e 's/pkgs\.xorg\.libXcomposite/pkgs.libXcomposite/g' \
          -e 's/pkgs\.xorg\.libXdamage/pkgs.libXdamage/g' \
          -e 's/pkgs\.xorg\.libXau/pkgs.libXau/g' \
          -e 's/pkgs\.xorg\.libXdmcp/pkgs.libXdmcp/g' \
          -e 's/pkgs\.xorg\.libSM/pkgs.libsm/g' \
          -e 's/pkgs\.xorg\.libICE/pkgs.libice/g' \
          $out/nix/packages.nix
        # Disable pythonRuntimeDepsCheckHook for vendored wheels (incomplete metadata)
        sed -i 's/doCheck = false;$/doCheck = false; dontCheckRuntimeDeps = true;/g' $out/nix/vendored-packages.nix
        sed -i 's/doCheck = false;$/doCheck = false; dontCheckRuntimeDeps = true;/g' $out/nix/python-overrides.nix
        # Strip cuda-bindings from PyTorch wheel metadata (bundled in wheel, not a real runtime dep)
        cat > /tmp/append-cuda-bindings.txt <<'EOF'
          sed -i '/^Requires-Dist: cuda-bindings/d' "$metadata"
        EOF
        sed -i '/Requires-Dist: triton/r /tmp/append-cuda-bindings.txt' $out/nix/python-overrides.nix
        # Patch PyTorch wheels to CUDA 12.6 so sm_61 (Pascal) GPUs remain supported
        sed -i \
          -e 's|download.pytorch.org/whl/cu128/torch-2.10.0%2Bcu128|download.pytorch.org/whl/cu126/torch-2.10.0%2Bcu126|g' \
          -e 's|sha256-Yo6JvVEQztfevuKlfGmVlyW3+8ZOq4GjndcORsfii6U=|sha256-KnpWkgbweWXv9pso4UdnZUC7C6bho5QQgCtuRwjLg1Y=|g' \
          -e 's|download.pytorch.org/whl/cu128/torchvision-0.25.0%2Bcu128|download.pytorch.org/whl/cu126/torchvision-0.25.0%2Bcu126|g' \
          -e 's|sha256-ElWgyiv5h6z58QO5bFxM/jQV/Eoe7xf6CK9SegSk9XM=|sha256-WDEya2cQNmtEwBJM4Ze0Fre4lu+ic0DCNQgcx/UocOU=|g' \
          -e 's|download.pytorch.org/whl/cu128/torchaudio-2.10.0%2Bcu128|download.pytorch.org/whl/cu126/torchaudio-2.10.0%2Bcu126|g' \
          -e 's|sha256-0muRoXPO5tuav/aLSNZCNpUP/FYo0GRI7N16xWhB4Qo=|sha256-LjdtLa7OFVAjJ5tbqmJcdMr1sBPwmOCXAoTB8xxddlE=|g' \
          $out/nix/versions.nix
        # Patch comfy-aimdo to use the manylinux wheel that contains the compiled
        # CUDA extension (aimdo.so). The pure-Python wheel lacks it, breaking
        # DynamicVRAM / multi-GPU support.
        sed -i \
          -e 's|comfy_aimdo-0.2.12-py3-none-any.whl|comfy_aimdo-0.2.12-cp39-abi3-manylinux1_x86_64.manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_5_x86_64.whl|g' \
          -e 's|sha256-YP7JJ1LV16UeSeyyE+lUZl7YD69mS42rJEnBzB/kan4=|sha256-x+0Y0KMvRxF9/aoBxIvpjt8JociG6wXnFk6TM8ky+LM=|g' \
          $out/nix/versions.nix
      '';

      # cuda_compat is aarch64-linux only in CUDA 12.9 and its manifest lacks a valid
      # x86_64-linux redistributable, so we stub it out on x86_64. On aarch64 we fall
      # back to nixos-stable where the manifests are correct.
      # We use overrideScope (if available) so packages inside cudaPackages that
      # reference cuda_compat or auto-add-cuda-compat-runpath-hook see the stub.
      # Use the pre-built NVSHMEM library from PyPI instead of building from source.
      # nixpkgs' cudaPackages.libnvshmem (CUDA 12.9) fails to compile for sm_61 because
      # it uses __match_all_sync, which requires sm_75+. The PyPI wheel is compatible.
      libnvshmem-cu126 =
        let
          wheel = final.fetchurl {
            url = "https://files.pythonhosted.org/packages/b5/09/6ea3ea725f82e1e76684f0708bbedd871fc96da89945adeba65c3835a64c/nvidia_nvshmem_cu12-3.4.5-py3-none-manylinux2014_x86_64.manylinux_2_17_x86_64.whl";
            hash = "sha256-BC8lAPJMAh24oGxe7CU5An1XRg4cGnYgVaZVT3LDab0=";
          };
        in
        final.runCommand "libnvshmem-3.4.5" { } ''
          mkdir -p $out/lib
          ${final.unzip}/bin/unzip -j ${wheel} "nvidia/nvshmem/lib/libnvshmem_host.so.3" -d $out/lib
        '';

      cudaPackages =
        let
          cudaCompatOverrides = self: super: {
            cuda_compat =
              if isAarch64 then
                stable.cudaPackages.cuda_compat
              else
                prev.runCommand "cuda_compat-stub" { } "mkdir -p $out";
            auto-add-cuda-compat-runpath-hook =
              if isAarch64 then
                stable.cudaPackages.auto-add-cuda-compat-runpath-hook
              else
                prev.runCommand "auto-add-cuda-compat-runpath-hook-stub" { } ''
                  mkdir -p $out/nix-support
                  touch $out/nix-support/setup-hook
                '';
            libnvshmem = final.libnvshmem-cu126;
          };
        in
        if prev.cudaPackages ? overrideScope then
          prev.cudaPackages.overrideScope cudaCompatOverrides
        else
          prev.cudaPackages // (cudaCompatOverrides null prev.cudaPackages);

      # Build comfy-ui-cuda using comfyui-nix's pre-built PyTorch wheels,
      # patched to CUDA 12.6 so sm_61 (Pascal / GTX 1080 Ti) remains supported.
      comfy-ui-cuda =
        let
          comfyuiVersions = import "${final.comfyuiNixPatched}/nix/versions.nix";
          comfyuiPythonOverrides = import "${final.comfyuiNixPatched}/nix/python-overrides.nix" {
            pkgs = final;
            versions = comfyuiVersions;
            gpuSupport = "cuda";
          };
          ourPythonOverrides =
            self: super:
            let
              comfyOverrides = comfyuiPythonOverrides self super;
            in
            (removeAttrs comfyOverrides [
              "color-matcher"
            ])
            // {
              # mss tests require a running X11 display, unavailable in the Nix sandbox
              mss = super.mss.overridePythonAttrs (old: {
                doCheck = false;
              });
              # timm 1.0.26 optimizer tests fail with PyTorch 2.10.0 due to
              # missing _accelerator_graph_capture attribute on internal optimizers
              timm = super.timm.overridePythonAttrs (old: {
                disabledTestPaths = (old.disabledTestPaths or [ ]) ++ [ "tests/test_optim.py" ];
              });
            };
          comfyPkgs = import "${final.comfyuiNixPatched}/nix/packages.nix" {
            pkgs = final;
            lib = final.lib;
            versions = comfyuiVersions;
            gpuSupport = "cuda";
            pythonOverrides = ourPythonOverrides;
          };
        in
        comfyPkgs.default;
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
    # Each 1080 Ti only has 11 GB VRAM. --lowvram offloads weights to CPU/RAM
    # between steps, allowing 12 GB models to run without falling back to pure CPU.
    extraArgs = [ "--lowvram" ];
  };

  environment.systemPackages = with pkgs; [
    pkgs.comfy-ui-cuda
  ];
}
