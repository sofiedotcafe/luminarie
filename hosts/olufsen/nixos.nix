{ pkgs, ... }:
{
  modules.nixos = {
    profile.minimal = {
      enable = true;
      hostName = "olufsen";
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
      extraGroups = [
        "wheel"
      ];
      shell = pkgs.zsh;
      initialPassword = "nixos";
    };
    root.initialPassword = "nixos";
  };

  home-manager.users.sofie = {
    programs.home-manager.enable = true;
    imports = [
      ./home.nix
    ];
  };

  topology.self = {
    name = "Olufsen";

    interfaces.wlp4s0 = {
      network = "client";
      physicalConnections = [
        { node = "ap_lr"; interface = "wifi-client"; }
      ];
    };
  };

  programs = {
    zsh.enable = true;
  };

  system.stateVersion = "23.05";
}
