{
  home = {
    username = "sofie";
    homeDirectory = "/home/sofie";
  };

  modules.home = {
    desktop = {
      gnome.enable = true;
      catppuccin.enable = true;
    };

    programs = {
      firefox.enable = true;
      vscode.enable = true;
    };

    shell = {
      starship.enable = true;
      zsh.enable = true;
    };
  };

  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
