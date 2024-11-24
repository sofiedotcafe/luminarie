# Generated via dconf2nix: https://github.com/nix-commmunity/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "com/raggesilver/BlackBox" = {
      easy-copy-paste = true;
      font = "JetBrainsMonoNL Nerd Font Mono Bold 12";
      pretty = true;
      terminal-bell = false;
      theme-bold-is-bright = true;
      theme-dark = "Catppuccin Mocha";
    };

    "org/gnome/Fractal/Stable" = {
      markdown-enabled = true;
      sessions = "[[\"qnGweAFs\",{\"sections_expanded\":[\"verification-request\",\"invited\",\"favorite\",\"normal\",\"low-priority\"]}]]";
    };

    "org/gnome/clocks/state/window" = {
      maximized = false;
      panel-id = "world";
      size = mkTuple [
        870
        690
      ];
    };

    "org/gnome/control-center" = {
      last-panel = "multitasking";
      window-state = mkTuple [
        980
        640
        false
      ];
    };

    "org/gnome/desktop/app-folders" = {
      folder-children = [
        "Utilities"
        "YaST"
        "Pardus"
        "2e5bf672-f345-4c97-b5e0-722282c77b2c"
      ];
    };

    "org/gnome/desktop/app-folders/folders/2e5bf672-f345-4c97-b5e0-722282c77b2c" = {
      apps = [
        "Deep Rock Galactic.desktop"
        "Half-Life 2.desktop"
        "Euro Truck Simulator 2.desktop"
        "Star Citizen.desktop"
        "Stardew Valley.desktop"
        "Satisfactory.desktop"
        "To the Moon.desktop"
      ];
      name = "Games";
    };

    "org/gnome/desktop/app-folders/folders/Pardus" = {
      categories = [ "X-Pardus-Apps" ];
      name = "X-Pardus-Apps.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/Utilities" = {
      apps = [
        "gnome-abrt.desktop"
        "gnome-system-log.desktop"
        "nm-connection-editor.desktop"
        "org.gnome.baobab.desktop"
        "org.gnome.Connections.desktop"
        "org.gnome.DejaDup.desktop"
        "org.gnome.Dictionary.desktop"
        "org.gnome.DiskUtility.desktop"
        "org.gnome.Evince.desktop"
        "org.gnome.FileRoller.desktop"
        "org.gnome.fonts.desktop"
        "org.gnome.Loupe.desktop"
        "org.gnome.seahorse.Application.desktop"
        "org.gnome.tweaks.desktop"
        "org.gnome.Usage.desktop"
        "vinagre.desktop"
        "cups.desktop"
        "yelp.desktop"
        "simple-scan.desktop"
        "org.gnome.SystemMonitor.desktop"
        "org.gnome.Contacts.desktop"
        "org.gnome.Extensions.desktop"
        "org.gnome.Music.desktop"
        "org.gnome.Totem.desktop"
      ];
      categories = [ "X-GNOME-Utilities" ];
      name = "X-GNOME-Utilities.directory";
      translate = true;
    };

    "org/gnome/desktop/app-folders/folders/YaST" = {
      categories = [ "X-SuSE-YaST" ];
      name = "suse-yast.directory";
      translate = true;
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/symbolic-soup-l.jxl";
      picture-uri-dark = "file:///run/current-system/sw/share/backgrounds/gnome/symbolic-soup-d.jxl";
      primary-color = "#B9B5AE";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/input-sources" = {
      sources = [
        (mkTuple [
          "xkb"
          "fi"
        ])
      ];
      xkb-options = [ "terminate:ctrl_alt_bksp" ];
    };

    "org/gnome/desktop/interface" = {
      accent-color = "blue";
      color-scheme = "prefer-dark";
      cursor-size = 24;
      cursor-theme = "catppuccin-mocha-lavender-cursors";
      gtk-theme = "catppuccin-mocha-lavender-standard";
      icon-theme = "Papirus-Dark";
    };

    "org/gnome/desktop/notifications" = {
      application-children = [
        "org-gnome-characters"
        "com-raggesilver-blackbox"
        "firefox"
      ];
    };

    "org/gnome/desktop/notifications/application/com-raggesilver-blackbox" = {
      application-id = "com.raggesilver.BlackBox.desktop";
    };

    "org/gnome/desktop/notifications/application/firefox" = {
      application-id = "firefox.desktop";
    };

    "org/gnome/desktop/notifications/application/org-gnome-characters" = {
      application-id = "org.gnome.Characters.desktop";
    };

    "org/gnome/desktop/screensaver" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      picture-uri = "file:///run/current-system/sw/share/backgrounds/gnome/symbolic-soup-l.jxl";
      primary-color = "#B9B5AE";
      secondary-color = "#000000";
    };

    "org/gnome/desktop/wm/keybindings" = {
      maximize = [ ];
      move-to-workspace-1 = [ "<Shift><Super>1" ];
      move-to-workspace-2 = [ "<Shift><Super>2" ];
      move-to-workspace-3 = [ "<Shift><Super>3" ];
      move-to-workspace-4 = [ "<Shift><Super>4" ];
      switch-to-workspace-1 = [ "<Super>1" ];
      switch-to-workspace-2 = [ "<Super>2" ];
      switch-to-workspace-3 = [ "<Super>3" ];
      switch-to-workspace-4 = [ "<Super>4" ];
      unmaximize = [ ];
    };

    "org/gnome/desktop/wm/preferences" = {
      num-workspaces = 3;
    };

    "org/gnome/evolution-data-server" = {
      migrated = true;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      edge-tiling = false;
    };

    "org/gnome/mutter/keybindings" = {
      toggle-tiled-left = [ ];
      toggle-tiled-right = [ ];
    };

    "org/gnome/nautilus/preferences" = {
      migrated-gtk-settings = true;
    };

    "org/gnome/settings-daemon/plugins/color" = {
      night-light-schedule-automatic = false;
    };

    "org/gnome/shell" = {
      app-picker-layout = [
        [
          (mkDictionaryEntry [
            "2e5bf672-f345-4c97-b5e0-722282c77b2c"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 0)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "Utilities"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 1)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.Settings.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 2)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.Weather.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 3)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.clocks.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 4)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.Calendar.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 5)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.Calculator.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 6)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.TextEditor.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 7)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "org.gnome.Fractal.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 8)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "kvantummanager.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 9)
              ])
            ])
          ])
          (mkDictionaryEntry [
            "nixos-manual.desktop"
            (mkVariant [
              (mkDictionaryEntry [
                "position"
                (mkVariant 10)
              ])
            ])
          ])
        ]
      ];
      disable-user-extensions = false;
      disabled-extensions = [ ];
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "blur-my-shell@aunetx"
        "clipboard-history@alexsaveau.dev"
        "quick-settings-avatar@d-go"
        "workspace-indicator@gnome-shell-extensions.gcampax.github.com"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "tilingshell@ferrarodomenico.com"
      ];
      favorite-apps = [
        "org.gnome.Nautilus.desktop"
        "steam.desktop"
        "com.raggesilver.BlackBox.desktop"
        "code.desktop"
        "firefox.desktop"
      ];
      last-selected-power-profile = "performance";
      welcome-dialog-last-shown-version = "47.1";
    };

    "org/gnome/shell/extensions/blur-my-shell" = {
      settings-version = 2;
    };

    "org/gnome/shell/extensions/blur-my-shell/appfolder" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/applications" = {
      blur = true;
      dynamic-opacity = true;
      opacity = 225;
    };

    "org/gnome/shell/extensions/blur-my-shell/dash-to-dock" = {
      blur = true;
      brightness = mkDouble "0.6";
      sigma = 30;
      static-blur = true;
      style-dash-to-dock = 0;
    };

    "org/gnome/shell/extensions/blur-my-shell/panel" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/blur-my-shell/window-list" = {
      brightness = mkDouble "0.6";
      sigma = 30;
    };

    "org/gnome/shell/extensions/tilingshell" = {
      last-version-name-installed = "14";
      layouts-json = "[{\"id\":\"Layout 1\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[1,2]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[2,3]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]},{\"x\":0.78,\"y\":0.5,\"width\":0.22,\"height\":0.5,\"groups\":[3,4]}]},{\"id\":\"Layout 2\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[1]},{\"x\":0.22,\"y\":0,\"width\":0.56,\"height\":1,\"groups\":[1,2]},{\"x\":0.78,\"y\":0,\"width\":0.22,\"height\":1,\"groups\":[2]}]},{\"id\":\"Layout 3\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.33,\"height\":1,\"groups\":[1]},{\"x\":0.33,\"y\":0,\"width\":0.67,\"height\":1,\"groups\":[1]}]},{\"id\":\"Layout 4\",\"tiles\":[{\"x\":0,\"y\":0,\"width\":0.67,\"height\":1,\"groups\":[1]},{\"x\":0.67,\"y\":0,\"width\":0.33,\"height\":1,\"groups\":[1]}]}]";
      overridden-settings = "{\"org.gnome.mutter.keybindings\":{\"toggle-tiled-right\":\"['<Super>Right']\",\"toggle-tiled-left\":\"['<Super>Left']\"},\"org.gnome.desktop.wm.keybindings\":{\"maximize\":\"['<Super>Up']\",\"unmaximize\":\"['<Super>Down', '<Alt>F5']\"},\"org.gnome.mutter\":{\"edge-tiling\":\"false\"}}";
      selected-layouts = [ "Layout 1" ];
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "catppuccin-mocha-lavender-standard";
    };

    "org/gnome/shell/keybindings" = {
      switch-to-application-1 = [ ];
      switch-to-application-2 = [ ];
      switch-to-application-3 = [ ];
      switch-to-application-4 = [ ];
      switch-to-application-5 = [ ];
      switch-to-application-6 = [ ];
      switch-to-application-7 = [ ];
      switch-to-application-8 = [ ];
      switch-to-application-9 = [ ];
    };

    "org/gnome/shell/world-clocks" = {
      locations = mkArray "v" [ ];
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 165;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "ascending";
      type-format = "category";
      window-position = mkTuple [
        103
        103
      ];
      window-size = mkTuple [
        1231
        902
      ];
    };

  };
}
