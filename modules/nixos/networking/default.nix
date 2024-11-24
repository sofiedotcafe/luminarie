{ lib, config, ... }:
with lib;
{
  options.modules.nixos = {
    networking = mkOption {
      example = ''
        {
          interfaces.eth0.useDHCP = true;
          hostName = "my-nixos-host";
          domainName = "local";
        }
      '';
      type = types.attrs;
      description = ''
        The networking configuration of the system,
        possible values: see https://search.nixos.org/options?show=networking
      '';
    };
  };
  config = {
    inherit (config.modules.nixos) networking;
  };
}
