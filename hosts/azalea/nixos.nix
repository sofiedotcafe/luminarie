{ config, ... }:
{
  modules.nixos = {
    language = {
      layout = "fi";
      time = "Europe/Helsinki";
    };

    users = {
      sofie = {
        shell = config.modules.nixos.shell.package;
        isNormalUser = true;
        extraGroups = [ "wheel" ];
      };
    };

    networking = {
      hostName = "azalea";
      networkmanager.enable = true;
    };

    desktop.session.gnome.enable = true;

    boot = {
      systemd.enable = true;
      lanzaboote.enable = true;
      plymouth.enable = true;
    };

    programs.steam.enable = true;
  };

  system.stateVersion = "23.05";
}
