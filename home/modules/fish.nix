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

      # Fix nix-shell prompt with Nerd Font Nix logo
      function __fish_nix_shell_prompt
          if test -n "$IN_NIX_SHELL"
              printf '%s ' (set_color blue)(printf '\uf313')(set_color normal)
          end
      end

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
