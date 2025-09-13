{
  inputs,
  sofLib,
  ...
}:
let
  inherit (sofLib) mkHome;

  modules = with inputs; [
    catppuccin.homeModules.catppuccin
    qt-decorations.homeModules.qt-decorations

    arkenfox.hmModules.arkenfox
  ];
in
{
  flake.homeConfigurations."sofie@azalea" = mkHome {
    name = "sofie";
    system = "x86_64-linux";
    inherit modules;
  };
}
