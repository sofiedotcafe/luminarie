{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop.gnome;
  inherit (config.modules.home.desktop) catppuccin;

  inherit (config.catppuccin) accent flavor;

  capitalize = str: lib.toUpper (lib.substring 0 1 str) + lib.substring 1 (lib.stringLength str) str;

  shade = if flavor == "latte" then "light" else "dark";
  tweaks =
    if flavor == "frappe" then
      [ "frappe" ]
    else if flavor == "macchiato" then
      [ "macchiato" ]
    else
      [ ];

  size = "standard";
in
{
  config = mkIf (cfg.enable && catppuccin.enable) {
    catppuccin.cursors.enable = true;
    home.pointerCursor = {
      gtk.enable = true;
      size = 24;
    };
    gtk =
      let
        colors = [
          "rosewater"
          "flamingo"
          "pink"
          "mauve"
          "red"
          "maroon"
          "peach"
          "yellow"
          "green"
          "teal"
          "sky"
          "sapphire"
          "blue"
          "lavender"
          "grey"
        ];

        name = "Catppuccin-GTK${
          lib.concatStrings (
            map (color: "-${capitalize color}") (
              if accent == "default" then
                [ ]
              else if accent == "all" then
                map capitalize colors
              else
                [ accent ]
            )
          )
        }-${capitalize shade}";
      in
      {
        enable = true;
        theme = {
          inherit name;
          package = pkgs.magnetic-catppuccin-gtk.override {
            inherit shade tweaks size;
            accent = [ accent ];
          };
        };
        iconTheme =
          let
            iconShade = if flavor == "latte" then "Light" else "Dark";
          in
          lib.mkForce {
            name = "Papirus-${iconShade}";
            package = pkgs.catppuccin-papirus-folders.override { inherit accent flavor; };
          };
      };
    home.packages = [ pkgs.gnomeExtensions.user-themes ];
    dconf.settings = {
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = [ "user-theme@gnome-shell-extensions.gcampax.github.com" ];
      };
      "org/gnome/shell/extensions/user-theme" = {
        inherit (config.gtk.theme) name;
      };
      "org/gnome/desktop/interface" = {
        color-scheme = if flavor == "latte" then "default" else "prefer-dark";
      };
    };
  };
}
