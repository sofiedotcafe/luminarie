{
  inputs,
  lib,
  withSystem,
  ...
}:
let
  sofLib = inputs.nixpkgs.lib.makeExtensible (self: {
    helpers = import ./helpers { inherit inputs withSystem; };

    inherit (self.helpers) mkHome mkSystem;
  });
in
{
  flake.lib = sofLib;
  _module.args = { inherit sofLib; };
  perSystem._module.args = { inherit sofLib; };
}
