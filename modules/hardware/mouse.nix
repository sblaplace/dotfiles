{
  config,
  lib,
  pkgs,
  ...
}:

{
  services.libinput.mouse.transformationMatrix = "1.0 0 0 0 1.0 0 0 0 0.25";
}
