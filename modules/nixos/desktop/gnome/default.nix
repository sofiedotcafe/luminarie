{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.desktop.gnome;

  cursor = {
    package =
      pkgs.catppuccin-cursors."${cfg.shell.catppuccin.flavor}${lib.toSentenceCase cfg.shell.catppuccin.accent}";

    name = "catppuccin-${cfg.shell.catppuccin.flavor}-${cfg.shell.catppuccin.accent}-cursors";
  };

  theme =
    let
      name =
        "Catppuccin-GTK"
        + lib.concatStrings (
          map (c: "-${lib.toUpper (lib.substring 0 1 c) + lib.substring 1 (lib.stringLength c) c}") (
            if cfg.shell.catppuccin.accent == "default" then
              [ ]
            else if cfg.shell.catppuccin.accent == "all" then
              [
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
              ]
            else
              [ cfg.shell.catppuccin.accent ]
          )
        )
        + "-"
        + (
          lib.toUpper (lib.substring 0 1 (if cfg.shell.catppuccin.flavor == "latte" then "light" else "dark"))
          + lib.substring 1 (lib.stringLength (
            if cfg.shell.catppuccin.flavor == "latte" then "light" else "dark"
          )) (if cfg.shell.catppuccin.flavor == "latte" then "light" else "dark")
        );
    in
    "${
      pkgs.magnetic-catppuccin-gtk.override {
        shade = if cfg.shell.catppuccin.flavor == "latte" then "light" else "dark";
        tweaks =
          if cfg.shell.catppuccin.flavor == "frappe" then
            [ "frappe" ]
          else if cfg.shell.catppuccin.flavor == "macchiato" then
            [ "macchiato" ]
          else
            [ ];
        size = "standard";
        accent = [ cfg.shell.catppuccin.accent ];
      }
    }/share/themes/${name}/gnome-shell/";
in
{
  options.modules.nixos.desktop.gnome = {
    enable = mkEnableOption "gnome";

    shell.catppuccin = {
      enable = mkEnableOption "Catppuccin GNOME Shell theme";
      flavor = mkOption {
        type = types.str;
        default = "mocha";
        description = "Catppuccin flavor.";
      };
      accent = mkOption {
        type = types.str;
        default = "lavender";
        description = "Catppuccin accent.";
      };
    };
  };

  config = mkIf cfg.enable {
    nixpkgs.overlays = [
      (_: prev: {
        gnome-shell = prev.gnome-shell.overrideAttrs (old: {
          postInstall =
            (old.postInstall or "")
            + lib.optionalString cfg.shell.catppuccin.enable ''
              mkdir theme
              cp -r ${theme}/. theme/

              chmod u+w theme/gnome-shell.css
              cat >> theme/gnome-shell.css << 'EOF'
              .login-dialog StEntry,
              .login-dialog StEntry ClutterText,
              .login-dialog StEntry StLabel.hint-text,
              .unlock-dialog StEntry,
              .unlock-dialog StEntry ClutterText,
              .unlock-dialog StEntry StLabel.hint-text {
                  color: #eff1f5 !important;
                  foreground-color: #eff1f5 !important;
                  caret-color: #eff1f5 !important;
                  icon-color: #eff1f5 !important;
              }

              .login-dialog-button.a11y-button{
                opacity:0 !important;
                pointer-events:none !important;
                width:0 !important;
                height:0 !important;
                margin:0 !important;
                padding:0 !important;
              }

              .popup-menu-item {
                padding: 9px 12px !important;    /* 1.5 * 6px, 2 * 6px */
                spacing: 6px !important;         /* base_padding */
              }

              .popup-menu .popup-sub-menu {
                padding: 12px !important;        /* scaled_padding * 2 */
                margin: 4px !important;          /* base_margin */
                border-radius: 12px !important;  /* base_border_radius * 1.5 */
              }
              EOF

              echo "<gresources><gresource prefix=\"/org/gnome/shell/theme\">" > m.xml
              for f in $(cd theme && find . -type f | sed 's|^\./||'); do
                echo "<file>$f</file>" >> m.xml
              done
              echo "</gresource></gresources>" >> m.xml

              glib-compile-resources \
                --sourcedir=theme \
                --target=$out/share/gnome-shell/gnome-shell-theme.gresource \
                m.xml
            '';
        });
      })
    ];

    environment.sessionVariables = {
      XCURSOR_THEME = mkDefault cursor.name;
      XCURSOR_SIZE = mkDefault "24";
      XCURSOR_PATH = [ "/run/current-system/sw/share/icons" ];
    };

    programs.dconf.profiles.gdm.databases = lib.mkIf cfg.shell.catppuccin.enable [
      {
        settings."org/gnome/desktop/interface" = {
          cursor-theme = cursor.name;
          cursor-size = lib.gvariant.mkInt32 24;
        };
      }
    ];

    services = {
      displayManager = {
        enable = true;
        gdm.enable = true;
      };

      desktopManager.gnome = {
        enable = true;
        extraGSettingsOverrides = ''
          [org.gnome.mutter]
          experimental-features=['scale-monitor-framebuffer', 'variable-refresh-rate', 'xwayland-native-scaling']
          check-alive-timeout=${lib.gvariant.mkUint32 (15 * 1000)}
        '';
        extraGSettingsOverridePackages = [ pkgs.mutter ];
      };

      gnome = {
        tinysparql.enable = true;
        localsearch.enable = true;
      };

      gvfs.enable = true;

      pipewire = {
        enable = true;
        pulse.enable = true;
        jack.enable = true;
        alsa.enable = true;
        alsa.support32Bit = true;
      };

      system76-scheduler.enable = true;

      printing = {
        enable = true;
        drivers = with pkgs; [ brlaser ];
      };

      avahi = {
        enable = true;
        nssmdns4 = true;
        openFirewall = true;
      };
    };

    environment = {
      systemPackages =
        with pkgs;
        [
          amberol
          blackbox-terminal
          cavalier
          papers
          fractal
        ]
        ++ lib.optional cfg.shell.catppuccin.enable cursor.package;

      gnome.excludePackages = with pkgs; [
        gnome-console
        gnome-music
        epiphany
        geary
        snapshot
        evince
      ];

      sessionVariables.GST_PLUGIN_SYSTEM_PATH_1_0 = lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" (
        with pkgs.gst_all_1;
        [
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav
        ]
      );
    };
  };
}
