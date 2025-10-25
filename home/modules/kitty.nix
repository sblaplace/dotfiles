{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    font = {
      name = "FiraCode Nerd Font";
      size = 11;
    };

    settings = {
      # Performance
      repaint_delay = 10;
      input_delay = 3;
      sync_to_monitor = "yes";

      # Appearance
      background_opacity = "0.95";
      window_padding_width = 4;
      
      # Shell integration
      shell_integration = "enabled";
      
      # Cursor
      cursor_shape = "block";
      cursor_blink_interval = 0;
      
      # Scrollback
      scrollback_lines = 10000;
      
      # Bell
      enable_audio_bell = "no";
      
      # URLs
      url_style = "curly";
      detect_urls = "yes";
    };

    # You can add a theme here
    # theme = "Dracula";
  };
}
