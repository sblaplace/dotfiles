{ config, pkgs, lib, ... }:

{
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
    nodejs      # Required if using any MCP-based tools
    python3     # Required for native Workspace tools
  ];
}

