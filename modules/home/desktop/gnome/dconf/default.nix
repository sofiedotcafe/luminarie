{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.desktop;
in
{
  config = mkIf cfg.gnome.enable {
    dconf.settings = {
      "org/gnome/mutter" = {
        dynamic-workspaces = false;
      };

      "org/gnome/desktop/wm/preferences" = {
        num-workspaces = last cfg.workspaces;
      };

      "org/gnome/desktop/wm/keybindings" = builtins.listToAttrs (
        let
          workspaces = map toString cfg.workspaces;
        in
        (map (n: {
          name = "move-to-workspace-${n}";
          value = [ "<Shift><Super>${n}" ];
        }) workspaces)
        ++ (map (n: {
          name = "switch-to-workspace-${n}";
          value = [ "<Super>${n}" ];
        }) workspaces)
      );

      "org/gnome/shell/keybindings" = builtins.listToAttrs (
        map (n: {
          name = "switch-to-application-${n}";
          value = [ ];
        }) (map toString (range 1 9))
      );
    };
  };
}
