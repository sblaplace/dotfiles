{ config, pkgs, ... }:

{
  programs.git = {
    enable = true;    
    lfs.enable = true;
    settings = {
      alias = {
        st = "status";
        co = "checkout";
        br = "branch";
        ci = "commit";
        unstage = "reset HEAD --";
        last = "log -1 HEAD";
        visual = "log --graph --oneline --all";
      };
      user = {
        name = "Sarah Laplace";
        email = "sblaplace@gmail.com"
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      core.editor = "vim";
    };
  };
}
