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
    '';

    interactiveShellInit = ''
      # Add any interactive-only config here
    '';
  };
}
