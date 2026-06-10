{ lib, ... }:
{
  imports = [
    ./desktop
    ./services
    ./programs
    ./shell
  ];

  programs.home-manager.enable = lib.mkDefault false;
}
