{
  modules.nixos = {
    language = {
      layout = "fi";
      time = "Europe/Helsinki";
    };

    profile.minimal = {
      enable = true;
      hostName = "cedarix";
      interactiveSudo = false;

      initiallyDisableRoot = true;
      ssh = {
        allowPasswords = true;
        allowRootLogin = true;
      };
    };
  };

  users.users = {
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      initialPassword = "";
    };
  };

  services.getty.autologinUser = "nixos";

  system.stateVersion = "23.05";
}
