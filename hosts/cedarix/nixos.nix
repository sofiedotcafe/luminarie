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

      ssh = {
        allowPasswords = true;
        allowRootLogin = true;
      };
    };

    services.klipper = {
      enable = true;
      configuration = ./klipper;
    };
  };

  system.stateVersion = "23.05";
}
