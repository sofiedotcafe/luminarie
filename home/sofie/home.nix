{
  pkgs,
  sofLib,
  ...
}:
{
  home = {
    username = "sofie";
    homeDirectory = "/home/sofie";
  };

  modules.home = {
    desktop = {
      gnome.enable = true;
      catppuccin.enable = true;
    };

    programs = {
      firefox.enable = true;
      vscode.enable = true;
    };

    shell = {
      starship.enable = true;
      zsh.enable = true;
    };
  };

  systemd.user.startServices = "sd-switch";

  home.packages = with pkgs; [
    prismlauncher
  ];
  xdg.dataFile."PrismLauncher/instances/WynnicEnchantments".source = sofLib.fetchPackwizModpack {
    src = pkgs.fetchFromGitHub {
      owner = "Rafii2198";
      repo = "WynnicEnchantments";
      rev = "3d4115d4d24440e6e1e961e895433e2bb05332b3";
      hash = "sha256-0uKDMfc0Vbe1OmrMGMlHncaZmIccQjYEvCEiKmJC0S8=";
    };
    inherit pkgs;
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
