{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop;
  archives = "org.gnome.FileRoller.desktop";
in
{
  config = mkIf cfg.gnome.enable {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/zip" = [ archives ];
      };
    };
  };
}
