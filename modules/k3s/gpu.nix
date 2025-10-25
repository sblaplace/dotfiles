{ config, lib, pkgs, ... }:

{
  # NVIDIA Container Runtime
  hardware.nvidia-container-toolkit.enable = true;

  # Add containerd config for NVIDIA runtime
  virtualisation.containerd = {
    enable = true;
    settings = {
      plugins."io.containerd.grpc.v1.cri".containerd.runtimes.nvidia = {
        runtime_type = "io.containerd.runc.v2";
        options = {
          BinaryName = "${pkgs.nvidia-container-toolkit}/bin/nvidia-container-runtime";
        };
      };
    };
  };

  # K3s GPU labels and config
  services.k3s.extraFlags = toString [
    "--node-label=nvidia.com/gpu=true"
    "--node-label=gpu-type=nvidia"
    # For desktop with RTX
    # "--node-label=gpu-model=rtx-3080"
    # For Jetson
    # "--node-label=gpu-model=jetson-orin"
  ];

  # After cluster is up, install NVIDIA device plugin:
  # kubectl apply -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.0/nvidia-device-plugin.yml
}