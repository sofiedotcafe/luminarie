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
        "https://cache.lix.systems"
      ];

      extra-trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
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
