{ lib, ... }:
with lib;
{
  imports = [
    ./cosmic
    ./gnome
  ];

  options.modules.nixos.desktop.session = {
    cosmic.enable = mkEnableOption "cosmic";
    gnome.enable = mkEnableOption "gnome";
  };
}
