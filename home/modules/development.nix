{ config, pkgs, ... }:

{
  home.packages = with pkgs; [
    nodejs
    python3
    dotnet-sdk_8
    typst
    nixfmt
    helix
    rustc
    cargo
    rustfmt
    rust-analyzer
    clippy
  ];

  # Optional: configure helix
  programs.helix = {
    enable = true;
    settings = {
      theme = "default";
      editor = {
        line-number = "relative";
        cursorline = true;
        auto-save = true;
      };
    };
  };

  programs.vscode = {
    enable = true;
    # You can add extensions and settings here
  };
}
