{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;
    userName = "Sarah Laplace";
    userEmail = "sblaplace@gmail.com";
    
    extraConfig = {
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
    
    lfs.enable = true;
    
    # Optional: add some useful aliases
    aliases = {
      st = "status";
      co = "checkout";
      br = "branch";
      ci = "commit";
      unstage = "reset HEAD --";
      last = "log -1 HEAD";
      visual = "log --graph --oneline --all";
    };
  };
}
