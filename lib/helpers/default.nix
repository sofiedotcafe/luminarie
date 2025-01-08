{ inputs, withSystem, ... }:
{
  mkHome = import ./mkHome.nix { inherit inputs withSystem; };
  mkSystem = import ./mkSystem.nix { inherit inputs withSystem; };
}
