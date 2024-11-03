{ pkgs, lib, ... }:
{
  home = {
    username = "jh-devv";
    homeDirectory = "/home/jh-devv";
  };

  modules.home = {
    desktop.session.gnome.enable = true;

    programs =
      lib.genAttrs
        [
          "firefox"
          "fractal"
          "vscode"
        ]
        (_k: {
          enable = true;
        });
    services = lib.genAttrs [ "mpris-proxy" ] (_k: {
      enable = true;
    });

    shell = {
      package = pkgs.zsh;
      common.enable = true;
    };
  };

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
