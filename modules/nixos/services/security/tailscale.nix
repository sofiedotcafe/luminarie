{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.nixos.services.security.tailscale;
in
{
  options.modules.nixos.services.security.tailscale = {
    enable = lib.mkEnableOption "Tailscale and Headscale";

    headscale = {
      domain = lib.mkOption {
        type = lib.types.str;
        default = "sofie.cafe";
      };

      port = lib.mkOption {
        type = lib.types.int;
        default = 8080;
      };

      dataDir = lib.mkOption {
        type = lib.types.path;
        default = "/var/lib/headscale";
      };
    };
  };

  config = lib.mkIf cfg.enable {

    systemd.tmpfiles.rules = [
      "d ${cfg.headscale.dataDir} 0750 root root -"
      "d ${config.sops.secrets."headscale/secret_key".path} 0750 tailscale tailscale -"
    ];

    modules.nixos.networking.containerInterfaces.headscale = {
      zone = "cnt-dmz";
      id = 11;
      proxy = {
        enable = true;
        subdomain = "tail";
        port = cfg.headscale.port;
        tls = true;
      };
    };

    containers.headscale = {
      autoStart = true;

      bindMounts.${config.sops.secrets."headscale/client_secret".path} = {
        hostPath = config.sops.secrets."headscale/client_secret".path;
        isReadOnly = false;
      };

      bindMounts.${config.sops.secrets."headscale/secret_key".path} = {
        hostPath = config.sops.secrets."headscale/secret_key".path;
        isReadOnly = false;
      };

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        systemd.tmpfiles.rules = [
          "d ${cfg.headscale.dataDir} 0750 headscale headscale -"
          "f ${config.sops.secrets."headscale/client_secret".path} 0440 root headscale -"
          "f ${config.sops.secrets."headscale/secret_key".path} 0440 root headscale -"
        ];

        networking.firewall.allowedTCPPorts = [ cfg.headscale.port ];

        services.headscale = {
          enable = true;

          settings = {
            server_url = "https://tail.${cfg.headscale.domain}";
            listen_addr = "0.0.0.0:${toString cfg.headscale.port}";

            database = {
              type = "sqlite";
              sqlite = {
                path = "${cfg.headscale.dataDir}/db.sqlite";
              };
            };

            dns.magic_dns = false;
            dns.nameservers.global = [ config.modules.nixos.networking.zones.svc.gateway ];

            oidc = {
              issuer = "https://noseprint.sofie.cafe/application/o/headscale/";
              client_id = "HAuAwiKwBqE8VZfIZnptkJ8arghphUTYQFDKs0yn";
              client_secret_path = "${config.sops.secrets."headscale/client_secret".path}";

              scope = [
                "openid"
                "profile"
                "email"
                "groups"
              ];
              allowed_groups = [
                "authentik Admins"
              ];

              pkce.enable = true;
            };
          };
        };
      };
    };

    services.tailscale = {
      enable = true;

      authKeyFile = "${config.sops.secrets."headscale/secret_key".path}";
      openFirewall = true;

      extraUpFlags = [
        "--login-server=https://tail.${cfg.headscale.domain}"
        "--accept-dns=false"

        "--advertise-exit-node"
        "--advertise-routes=10.0.0.0/28,10.0.1.0/28"
      ];
    };
    boot.kernel.sysctl = {
      "net.ipv4.ip_forward" = true;
      "net.ipv6.conf.all.forwarding" = true;
    };
  };
}
