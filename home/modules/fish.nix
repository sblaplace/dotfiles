{ config, pkgs, ... }:

{
  programs.fish = {
    enable = true;

    shellAliases = {
      ll = "ls -lah";
      ".." = "cd ..";
      rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles#$(hostname)";
      home-rebuild = "home-manager switch --flake ~/dotfiles#laplace@$(hostname)";
    };

    shellInit = ''
      # Disable greeting
      set fish_greeting

      # Direnv integration
      direnv hook fish | source

      # Nix-your-shell integration
      if command -q nix-your-shell
          nix-your-shell fish | source
      end
    '';

    interactiveShellInit = ''
      # Add any interactive-only config here
    '';
  };
}
