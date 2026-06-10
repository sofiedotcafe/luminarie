{
  description = "A NixOS Flake for my NixOS infra! 🌸 (｡•̀ᴗ-)✧";

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      imports = [
        inputs.pre-commit-hooks.flakeModule

        ./overlays
        ./lib
        ./pkgs
        ./hosts
        ./topology

        ./devshell
      ];
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    lanzaboote = {
      url = "github:nix-community/lanzaboote/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    authentik-nix = {
      url = "github:nix-community/authentik-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-topology.url = "github:oddlama/nix-topology";

    impermanence.url = "github:nix-community/impermanence";

    disko.url = "github:nix-community/disko/master";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    catppuccin.url = "github:catppuccin/nix";

    qt-decorations = {
      url = "github:sofiedotcafe/qt-decorations";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixos-raspberrypi.url = "github:nvmd/nixos-raspberrypi/main";

    arkenfox.url = "github:dwarfmaster/arkenfox-nixos";
    nix-citizen.url = "github:LovingMelody/nix-citizen";
    steam-presence = {
      url = "github:JustTemmie/steam-presence";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
