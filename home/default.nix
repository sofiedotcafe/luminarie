{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkHome;

  modules = with inputs; [
    catppuccin.homeModules.catppuccin
    arkenfox.hmModules.arkenfox
  ];
in
{
  flake.homeConfigurations."sofie@azalea" = mkHome "sofie" "x86_64-linux" modules;
}
