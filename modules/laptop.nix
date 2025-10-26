{ config, pkgs, ... }:
{
  # Battery optimization
  services.tlp.enable = true;
  
  # Laptop power management
  services.logind = {
    lidSwitch = "suspend";
    lidSwitchExternalPower = "ignore";
  };
  
  # Better touchpad
  services.libinput.touchpad = {
    tapping = true;
    naturalScrolling = true;
  };
}