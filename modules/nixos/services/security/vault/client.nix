{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.nixos.services.security.vault.client;
  vault = config.modules.nixos.services.security.vault;
  traefik = config.modules.nixos.services.traefik;

  address =
    if cfg.traefik then
      "https://${vault.subdomain}.${traefik.internalDomain}"
    else
      "https://${vault.address}:${toString vault.port}";
in
{
  imports = with inputs; [
    systemd-vaultd.nixosModules.vaultAgent
    systemd-vaultd.nixosModules.systemdVaultd
  ];

  config = lib.mkIf cfg.enable {
    services.vault.agents.default = {
      settings = {
        vault = {
          address = address;
          tls_cacert = if cfg.traefik then "/etc/tls/node-ca.crt" else null;
        };
        auto_auth.method = [
          {
            type = "approle";
            config = {
              role_id_file_path = cfg.role;
              secret_id_file_path = cfg.secret;
              remove_secret_id_file_after_reading = false;
            };
          }
        ];
      };
    };

    systemd.services = lib.mapAttrs (_: clientCfg: {
      vault = {
        secrets = clientCfg.secrets;
      }
      // (lib.optionalAttrs (clientCfg.template != null) {
        inherit (clientCfg) template;
      })
      // (lib.optionalAttrs (clientCfg.environmentTemplate != null) {
        inherit (clientCfg) environmentTemplate;
      });
    }) cfg.services;
  };
}
