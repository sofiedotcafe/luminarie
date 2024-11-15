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
        cosmic.enable = mkEnableOption "cosmic";
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

      /*
        displays = mkOption {
          description = "Config for new displays";
          type =
            with types;
            listOf (submodule {
              options = {
                name = mkOption {
                  type = str;
                  description = "The name of the display, e.g. eDP-1";
                };

                wallpaper = mkOption {
                  type = path;
                  default = cfg.wallpaper;
                  description = "The local flake path of the wallpaper for the given display.";
                };

                workspaces = mkOption {
                  type = listOf int;
                  description = "List of workspace numbers";
                  default = [
                    1
                    2
                    3
                    4
                    5
                    6
                    7
                    8
                    9
                    10
                  ];
                };
              };
            });
          default = [ ];
        };
      */
    };
  };
}
