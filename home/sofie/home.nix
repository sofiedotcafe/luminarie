{ pkgs, lib, ... }:
{
  home = {
    username = "sofie";
    homeDirectory = "/home/sofie";
  };

  modules.home = {
    desktop = {
      session.gnome.enable = true;
      catppuccin.enable = true;
    };

    programs =
      lib.genAttrs
        [
          "firefox"
          "vscode"
        ]
        (_k: {
          enable = true;
        });

    shell = {
      package = pkgs.zsh;
      common.enable = true;
      starship.enable = true;
    };
  };

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
