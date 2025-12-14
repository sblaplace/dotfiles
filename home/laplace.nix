{
  config,
  pkgs,
  lib,
  hostname ? "unknown",
  ...
}:

{
  imports = [
    ./modules/fish.nix
    ./modules/kitty.nix
    ./modules/git.nix
    ./modules/development.nix
  ]
  ++
    lib.optionals
      (builtins.elem hostname [
        "neovenezia"
        "t450"
        "precision7730"
      ])
      [
        # Only import desktop apps on machines with GUI
        ./modules/desktop.nix
      ]
  ++ lib.optionals (builtins.pathExists ./machines/${hostname}.nix) [
    # Import machine-specific config if it exists
    (./machines + "/${hostname}.nix")
  ];

  home.username = "laplace";
  home.homeDirectory = "/home/laplace";
  home.stateVersion = "25.05";

  # Let Home Manager manage itself on standalone installations
  programs.home-manager.enable = true;

  # Basic packages that should be on all machines
  home.packages = with pkgs; [
    tree
    vim
    htop
    fastfetch
    unzip
    zip
    jq
    miller
    ffmpeg
    pandoc
    glow
    claude-code
    elan
    radare2
    nerd-fonts.fira-code
  ];

  # Starship prompt
  programs.starship = {
    enable = true;
    enableFishIntegration = true;
    settings = {
      nix_shell = {
        format = "via [$symbol$state( \\($name\\))]($style) ";
        symbol = " "; # Nerd Font Nix logo U+F313
      };
    };
  };

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
