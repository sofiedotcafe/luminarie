{
  lib,
  inputs,
  ...
}:
with lib;
{
  imports = [
    ./catppuccin
    ./gnome
  ];
  options.modules.home = {
    desktop = {
      gnome.enable = mkEnableOption "gnome";

      catppuccin = {
        enable = mkEnableOption "catppuccin";
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

      workspaces = {
        static = mkOption {
          type = types.listOf types.int;
          description = "List of workspace numbers as the static workspaces.";
          default = range 1 3;
        };
        dynamic = mkEnableOption "dynamic workspaces" // {
          default = true;
        };
      };
    };
  };
}
