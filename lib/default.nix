{
  inputs,
  withSystem,
  ...
}:
let
  sofLib = inputs.nixpkgs.lib.makeExtensible (self:
  # let
  #   lib = self;
  # in
  {
    helpers = import ./helpers { inherit inputs withSystem; };
    fetchers = import ./fetchers;

    inherit (self.helpers) mkHome mkSystem;
    inherit (self.fetchers) fetchPackwizModpack;
  });
in
{
  flake.lib = sofLib;
  _module.args = { inherit sofLib; };
  perSystem._module.args = { inherit sofLib; };
}
