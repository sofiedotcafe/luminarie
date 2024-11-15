{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.session.cosmic;
  file-explorer = "com.system76.CosmicFiles.desktop";
  zip-manager = "org.gnome.FileRoller.desktop";
in
{
  config = mkIf cfg.enable {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/zip" = [ zip-manager ];
        "inode/directory" = [ file-explorer ];
      };
    };
    home.packages = with pkgs; [
      cosmic-files
      file-roller
    ];
  };
}
