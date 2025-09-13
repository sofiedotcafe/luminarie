{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.services.openrgb;
in
{
  options.modules.nixos.services.openrgb = {
    enable = mkEnableOption "openrgb";

    package = mkOption {
      type = types.package;
      default = pkgs.openrgb-with-all-plugins.overrideAttrs (_: {
        # version = "0-unstable-2025-08-06";
        # src = pkgs.fetchFromGitLab {
        #   owner = "CalcProgrammer1";
        #   repo = "OpenRGB";
        #   rev = "e6190ec2756fe99971f057621efc234680db79ec";
        #   hash = "sha256-Q64ouAIJFxp5cmt+zjYPqIHjcXBz3Ueulj7/lAsOVVA=";
        # };
      });
    };
  };

  config = mkIf cfg.enable {
    services.hardware.openrgb = {
      enable = true;
      inherit (cfg) package;
    };
    environment.systemPackages = [ cfg.package ];
  };
}
