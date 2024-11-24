{ lib, ... }:
with lib;
{
  imports = [
    ./session
  ];

  options.modules.nixos.desktop.session = {
    gnome.enable = mkEnableOption "gnome";
  };
}
