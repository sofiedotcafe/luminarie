{ config, ... }:
{
  modules.nixos = {
    language = {
      layout = "fi";
      time = "Europe/Helsinki";
    };

    users = {
      nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        initialHashedPassword = "";
      };
      root.initialHashedPassword = "";
    };

    networking = {
      hostName = "cedarix";
      networkmanager.enable = true;
    };
  };

  services = {
    getty.autologinUser = "nixos";
    openssh.enable = true;
  };

  system.stateVersion = "23.05";
}
