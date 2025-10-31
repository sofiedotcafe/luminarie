{
  pkgs,
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
    vintagestory
    rsi-launcher
    signal-desktop
    (prismlauncher.override {
      jdks = with pkgs; [
        jdk23
        jdk21
        jdk17
        jdk8
      ];
    })
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "dotnet-runtime-7.0.20" # Vintage Story
  ];

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
