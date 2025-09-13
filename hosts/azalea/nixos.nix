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
    gamemode.enable = true;
    gamescope.enable = true;
    zsh.enable = true;

    virt-manager.enable = true;
  };

  virtualisation = {
    libvirtd.enable = true;
    spiceUSBRedirection.enable = true;
  };

  services.pcscd.enable = true;

  system.stateVersion = "23.05";
}
