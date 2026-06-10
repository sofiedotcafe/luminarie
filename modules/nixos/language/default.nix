{ config, lib, ... }:
with lib;
let
  cfg = config.modules.nixos.language;
in
{
  options.modules.nixos = {
    language = {
      locale = mkOption {
        type = types.str;
        default = "en_US.UTF-8";
        example = "fi_FI.UTF-8";
      };
      layout = mkOption {
        type = types.str;
        default = "us";
        example = "fi";
      };
      time = mkOption {
        type = types.str;
        default = "America/New_York";
        example = "Europe/Helsinki";
      };
    };
  };
  config = {
    services.xserver.xkb.layout = cfg.layout;
    console.useXkbConfig = true;

    i18n.defaultLocale = cfg.locale;

    time.timeZone = cfg.time;
  };
}
