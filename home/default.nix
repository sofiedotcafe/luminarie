{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkHome;

  inherit (inputs.catppuccin.homeManagerModules) catppuccin;
  inherit (inputs.arkenfox.hmModules) arkenfox;
  modules = [
    catppuccin
    arkenfox
  ];
in
{
  flake.homeConfigurations."sofie@azalea" = mkHome "sofie" "x86_64-linux" modules;
}
