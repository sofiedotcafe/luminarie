{ pkgs, ... }:
{
  modules.nixos = {
    profile.minimal = {
      enable = true;
      hostName = "azalea";
    };
    language = {
      layout = "fi";
      time = "Europe/Helsinki";
    };
    desktop.gnome.enable = true;
  };

  users.users = {
    sofie = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      shell = pkgs.zsh;
    };
  };

  programs = {
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
    };
    gamemode.enable = true;
    zsh.enable = true;
  };

  i18n.inputMethod = {
    enable = true;
    type = "ibus";
  };

  system.stateVersion = "23.05";
}
