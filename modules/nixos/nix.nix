{
  lib,
  inputs,
  config,
  ...
}:
{
  nix = {
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      experimental-features = "nix-command flakes pipe-operator";
      auto-optimise-store = true;

      extra-substituters = [
        "https://nix-community.cachix.org"
        "https://catppuccin.cachix.org"
      ];

      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "catppuccin.cachix.org-1:noG/4HkbhJb+lUAdKrph6LaozJvAeEEZj4N732IysmU="
      ];
    };
  };

  nixpkgs = {
    overlays = [ inputs.self.overlays.default ];
    config = {
      allowUnfree = true;
    };
  };
}
