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

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";
}
