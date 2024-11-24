{
  lib,
  inputs,
  ...
}:
with lib;
{
  imports = [
    ./catppuccin
    ./session
  ];
  options.modules.home = {
    desktop = {
      /*
        power = {
          lockscreen = {
            enable = mkEnableOption "automatic system lockscreen";
            timeout = mkOption {
              default = 5;
              example = 5;
              type = types.int;
              description = "Timeout for automatic system lockscreen (in minutes)";
            };
            wallpaper = mkOption {
              type = types.path;
              default = cfg.wallpaper;
              description = "The local flake path of the wallpaper for the lockscreen.";
            };
          };
          suspend = {
            enable = mkEnableOption "automatic system suspend";
            timeout = mkOption {
              default = 30;
              example = 30;
              type = types.int;
              description = "Timeout for automatic system suspend (in minutes)";
            };
          };
        };
      */

      session = {
        gnome.enable = mkEnableOption "gnome";
      };

      catppuccin = {
        enable = mkEnableOption "flavor";
        flavor = mkOption {
          type = types.str;
          description = "The variant of Catppuccin to use.";
          default = "mocha";
        };
        accent = mkOption {
          type = types.str;
          description = "The accent of Catppuccin to use.";
          default = "lavender";
        };
      };

      wallpaper = mkOption {
        type = types.path;
        description = "The local flake path of the wallpaper as default.";
        default = builtins.toString "${inputs.self}/assets/city.png";
      };

      workspaces = mkOption {
        type = types.listOf types.int;
        description = "List of workspace numbers";
        default = range 1 3;
      };
    };
  };
}
