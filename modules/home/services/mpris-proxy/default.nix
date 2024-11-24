{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.home.services.mpris-proxy;
in
{
  options.modules.home = {
    services = genAttrs [ "mpris-proxy" ] (k: {
      enable = mkEnableOption k;
    });
  };
  config = mkIf cfg.enable { services.mpris-proxy.enable = true; };
}
