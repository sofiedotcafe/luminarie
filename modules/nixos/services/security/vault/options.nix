{ lib, config, ... }: {
  options.modules.nixos.services.security.vault = {
    enable = lib.mkEnableOption "Vault server container";
    address = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = config.modules.nixos.networking.containerInterfaces.vault.address or "10.0.255.20";
    };
    port = lib.mkOption {
      type = lib.types.int;
      default = 8200;
    };
    subdomain = lib.mkOption {
      type = lib.types.str;
      default = "collar";
    };
    client = {
      enable = lib.mkEnableOption "Vault Client integration via systemd-vaultd";

      traefik = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Whether to access Vault via Traefik domain route or directly via container IP.
          Set to false for core infra like Traefik itself so it can boot using direct IP.
        '';
      };

      role = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/vault-agent/roleID";
        description = "Path to AppRole Role ID file.";
      };

      secret = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/vault-agent/secretID";
        description = "Path to AppRole Secret ID file.";
      };

      services = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              template = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };

              secrets = lib.mkOption {
                type = lib.types.attrsOf lib.types.attrs;
                default = { };
              };

              environmentTemplate = lib.mkOption {
                type = lib.types.nullOr lib.types.str;
                default = null;
              };
            };
          }
        );
        default = { };
        description = "Services requiring secrets mapped through systemd-vaultd.";
      };
    };
  };
}
