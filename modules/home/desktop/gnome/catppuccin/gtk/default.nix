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
          package =
            (pkgs.magnetic-catppuccin-gtk.overrideAttrs
              {
                version = "0-unstable-2025-08-06";
                src = pkgs.fetchFromGitHub {
                  owner = "Fausto-Korpsvart";
                  repo = "Catppuccin-GTK-Theme";
                  rev = "7e1ae7882a288ed5b80ddf58c1847c290615075c";
                  hash = "sha256-FFVUVtLS7XpTVo4/pSEpUh759y/SkkksS1UC25yFor4=";
                };
                patches = [
                  (pkgs.fetchpatch {
                    url = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme/pull/62.patch";
                    hash = "sha256-5j2S9QJ9AuY2yegsuwPm9sPaS7DkGZiydbkEcs6JTtE=";
                  })
                ];
              })
              .override
              {
                lib = lib.extend (
                  _: prev: {
                    checkListOfEnum =
                      name: allowed: actual:
                      let
                        extended =
                          if prev.hasInfix "accent" (prev.toLower name) then
                            [
                              "default"
                              "all"
                            ]
                            ++ colors
                          else
                            allowed;
                      in
                      prev.checkListOfEnum name extended actual;
                  }
                );
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
