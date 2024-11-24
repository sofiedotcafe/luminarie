{ config, lib, ... }:
with lib;
{
  options.modules.nixos = {
    users = mkOption {
      example = ''
        {
          users.users.alice = {
            isNormalUser = true;
            extraGroups = [ "wheel" "networkmanager" ];
            hashedPassword = "$6$saltsalt$...";
          };
        }
      '';
      type = types.attrs;
      description = ''
        The user configuration of the system,
        possible values: see https://search.nixos.org/options?show=users.users
      '';
    };
  };
  config = {
    users = {
      inherit (config.modules.nixos) users;
    };
  };
}
