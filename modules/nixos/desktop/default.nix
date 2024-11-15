{ lib, ... }:
with lib;
{
  imports = [
    ./session
  ];

  options.modules.nixos.desktop.session = {
    cosmic.enable = mkEnableOption "cosmic";
    gnome.enable = mkEnableOption "gnome";
  };
}
