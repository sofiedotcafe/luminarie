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
    desktop.gnome.shell.catppuccin.enable = true;
  };

  users.users = {
    sofie = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "libvirtd"
      ];
      shell = pkgs.zsh;
    };
  };

  home-manager.users.sofie = {
    programs.home-manager.enable = true;
    imports = [
      ./home.nix
    ];
  };

  topology.self = {
    name = "Azalea";
    interfaces.wlp1s0 = {
      network = "client";
      physicalConnections = [
        {
          node = "ap_lr";
          interface = "wifi-client";
        }
      ];
    };
  };

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = with pkgs; [
        proton-ge-bin
      ];
    };
    gamescope = {
      enable = true;
      args = [
        "--backend sdl"
        "-f"
        "-w 2560 -h 1440"
      ];
      env = {
        SDL_VIDEODRIVER = "x11"; # gamescope currently has issues with mutter
      };
    };
    gamemode.enable = true;
    zsh.enable = true;

    nix-ld.enable = true;
  };

  environment.systemPackages = with pkgs; [
    jetbrains.idea-oss
    android-studio
    android-tools
  ];

  services.pcscd.enable = true;

  system.stateVersion = "23.05";
}
