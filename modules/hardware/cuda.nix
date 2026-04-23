{
  config,
  lib,
  pkgs,
  ...
}:

{
  nixpkgs.config.cudaCapabilities = [ "6.1" ];

  # 1. Ollama backend with CUDA (GTX 1080 Ti)
  services.ollama = {
    enable = true;
    package = pkgs.ollama-cuda;
  };
}
