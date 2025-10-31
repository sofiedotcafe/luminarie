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
    services.openrgb.enable = true;
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

    virt-manager.enable = true;
  };

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };
    spiceUSBRedirection.enable = true;
  };

  services.pcscd.enable = true;

  system.stateVersion = "23.05";
}
