{
  config,
  lib,
  inputs,
  ...
}:

let
  cfg = config.modules.nixos.services.traefik;
  net = config.modules.nixos.networking;

  allProxies = lib.concatLists (
    lib.mapAttrsToList (
      netName: iface:
      map
        (
          p:
          p
          // {
            containerName = netName;
            ip = iface.address;
            zone = iface.zone;
          }
        )
        (
          lib.filter (p: p != null && (p.enable or false) && p.subdomain != null && p.port != null) (
            lib.attrValues iface.proxy
          )
        )
    ) net.containerInterfaces
  );

  isDmz = ifaceZone: lib.hasInfix "dmz" (lib.toLower ifaceZone);

  enabledInternal = builtins.filter (p: !isDmz p.zone) allProxies;
  enabledDmz = builtins.filter (p: isDmz p.zone) allProxies;

  domainFor = p: if isDmz p.zone then cfg.externalDomain else cfg.internalDomain;

  mkHttpService = p: {
    "${p.subdomain}" = {
      loadBalancer = {
        servers = [ { url = "${p.protocol}://${p.ip}:${toString p.port}"; } ];
        serversTransport = lib.optionalString p.tls "node-transport";
      };
    };
  };

  mkHttpRouter = target: p: {
    "${p.subdomain}" = {
      rule = "Host(`${p.subdomain}.${domainFor p}`)";
      entryPoints = [ "websecure" ];
      service = p.subdomain;

      tls = lib.mkIf p.tls {
        certResolver = target;
      };

      middlewares = [ "forward-auth-headers" ];
      priority = 100;
    };
  };

in
{
  options.modules.nixos.services.traefik = {
    enable = lib.mkEnableOption "Traefik reverse proxy";

    internalDomain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain for internal Traefik routes";
    };

    externalDomain = lib.mkOption {
      type = lib.types.str;
      description = "Base domain for DMZ Traefik routes";
    };

    acme = {
      storage = lib.mkOption {
        type = lib.types.str;
        default = "/var/acme";
      };

      email = lib.mkOption {
        type = lib.types.str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    modules.nixos.networking.containerInterfaces.traefik = {
      zone = "svc";
      id = 10;
    };

    networking.firewall.allowedTCPPorts = [
      80
      443
    ];

    systemd.tmpfiles.rules = [
      "d /var/acme 0755 root root -"
      "d /var/log/traefik 0755 root root -"
      "d /etc/ssl 0755 root root -"
    ];

    systemd.services."container@traefik" = {
      after = [ "container@vault.service" ];
      requires = [ "container@vault.service" ];
    };

    systemd.services."container@traefik-dmz" = {
      after = [ "container@vault.service" ];
      requires = [ "container@vault.service" ];
    };

    containers.traefik = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = net.zones.svc.bridge;

      bindMounts = {
        ${cfg.acme.storage} = {
          hostPath = cfg.acme.storage;
          isReadOnly = false;
        };
        "/var/log/traefik" = {
          hostPath = "/var/log/traefik";
          isReadOnly = false;
        };
        "/etc/ssl/certs/node-ca.crt" = {
          hostPath = "/etc/ssl/node-ca.crt";
          isReadOnly = true;
        };
        "/etc/ssl/certs/node-client.crt" = {
          hostPath = "/etc/ssl/node-client.crt";
          isReadOnly = true;
        };
        "/etc/ssl/private/node-client.key" = {
          hostPath = "/etc/ssl/node-client.key";
          isReadOnly = true;
        };
      };

      config = { ... }: {
        imports = with inputs; [
          nix-topology.nixosModules.default

          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd

          "${inputs.self}/modules/nixos/services/security/vault/options.nix"
          "${inputs.self}/modules/nixos/services/security/vault/client.nix"
        ];

        system.stateVersion = "26.05";

        systemd.tmpfiles.rules = [
          "d /var/acme 0755 traefik traefik -"
          "f /var/acme/internal.json 0600 traefik traefik -"
          "d /var/log/traefik 0755 traefik traefik -"
          "f /var/log/traefik/access.log 0644 traefik traefik -"
          "f /var/log/traefik/traefik.log 0644 traefik traefik -"
        ];

        modules.nixos.services.security.vault.client = {
          enable = true;
          traefik = false;

          services.traefik.environmentTemplate = ''
            {{ with secret "kv/data/traefik" }}
            CF_DNS_API_TOKEN={{ .Data.data.cloudflare_dns_api_token }}
            {{ end }}
          '';
        };

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        services.traefik = {
          enable = true;

          staticConfigOptions = {
            log = {
              level = "DEBUG";
            };
            accessLog = {
              bufferingSize = 0;
              fields.defaultMode = "keep";
            };

            entryPoints.web.address = ":80";
            entryPoints.websecure.address = ":443";

            entryPoints.web.http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };

            certificatesResolvers.internal.acme = {
              email = cfg.acme.email;
              storage = "${cfg.acme.storage}/internal.json";
              dnsChallenge = {
                provider = "cloudflare";
                delayBeforeCheck = 0;
              };
            };

            http.serversTransports = {
              node-transport = {
                rootCAs = [ "/etc/ssl/certs/node-ca.crt" ];
                certificates = [
                  {
                    certFile = "/etc/ssl/certs/node-client.crt";
                    keyFile = "/etc/ssl/private/node-client.key";
                  }
                ];
              };
            };

            tracing = {
              serviceName = "traefik-internal";
              otlp.grpc = {
                endpoint = "${config.modules.nixos.services.observability.tempo.address}:${toString config.modules.nixos.services.observability.tempo.otlpPort}";
                insecure = true;
              };
            };
          };

          dynamicConfigOptions.http = {
            middlewares.forward-auth-headers.headers.customRequestHeaders = {
              "X-Forwarded-Proto" = "https";
              "X-Forwarded-Port" = "443";
            };

            services = lib.mkMerge (map mkHttpService enabledInternal);
            routers = lib.mkMerge (map (mkHttpRouter "internal") enabledInternal);
          };
        };
      };
    };

    modules.nixos.networking.containerInterfaces.traefik-dmz = {
      zone = "dmz";
      id = 10;
    };

    containers.traefik-dmz = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = net.zones.dmz.bridge;

      bindMounts = {
        ${cfg.acme.storage} = {
          hostPath = cfg.acme.storage;
          isReadOnly = false;
        };
        "/var/log/traefik" = {
          hostPath = "/var/log/traefik";
          isReadOnly = false;
        };
        "/etc/ssl/certs/node-ca.crt" = {
          hostPath = "/etc/ssl/node-ca.crt";
          isReadOnly = true;
        };
        "/etc/ssl/certs/node-client.crt" = {
          hostPath = "/etc/ssl/node-client.crt";
          isReadOnly = true;
        };
        "/etc/ssl/private/node-client.key" = {
          hostPath = "/etc/ssl/node-client.key";
          isReadOnly = true;
        };
      };

      config = { ... }: {
        imports = with inputs; [
          nix-topology.nixosModules.default

          systemd-vaultd.nixosModules.vaultAgent
          systemd-vaultd.nixosModules.systemdVaultd

          "${inputs.self}/modules/nixos/services/security/vault/options.nix"
          "${inputs.self}/modules/nixos/services/security/vault/client.nix"
        ];
        system.stateVersion = "26.05";

        networking.firewall.allowedTCPPorts = [
          80
          443
        ];

        systemd.tmpfiles.rules = [
          "d /var/acme 0755 traefik traefik -"
          "f /var/acme/external.json 0600 traefik traefik -"
          "d /var/log/traefik 0755 traefik traefik -"
          "f /var/log/traefik/access.log 0644 traefik traefik -"
          "f /var/log/traefik/traefik.log 0644 traefik traefik -"
        ];

        modules.nixos.services.security.vault.client = {
          enable = true;
          traefik = false;

          services.traefik.environmentTemplate = ''
            {{ with secret "kv/data/traefik" }}
            CF_DNS_API_TOKEN={{ .Data.data.cloudflare_dns_api_token }}
            {{ end }}
          '';
        };

        services.traefik = {
          enable = true;

          staticConfigOptions = {
            log = {
              level = "DEBUG";
            };
            accessLog = {
              bufferingSize = 0;
              fields.defaultMode = "keep";
            };

            entryPoints.web.address = ":80";
            entryPoints.websecure.address = ":443";

            entryPoints.web.http.redirections.entryPoint = {
              to = "websecure";
              scheme = "https";
            };

            certificatesResolvers.dmz.acme = {
              email = cfg.acme.email;
              storage = "${cfg.acme.storage}/external.json";
              dnsChallenge = {
                provider = "cloudflare";
                delayBeforeCheck = 0;
              };
            };

            http.serversTransports = {
              node-transport = {
                rootCAs = [ "/etc/ssl/certs/node-ca.crt" ];
                certificates = [
                  {
                    certFile = "/etc/ssl/certs/node-client.crt";
                    keyFile = "/etc/ssl/private/node-client.key";
                  }
                ];
              };
            };

            tracing = {
              serviceName = "traefik-dmz";
              otlp.grpc = {
                endpoint = "${config.modules.nixos.services.observability.tempo.address}:${toString config.modules.nixos.services.observability.tempo.otlpPort}";
                insecure = true;
              };
            };
          };

          dynamicConfigOptions.http = {
            middlewares.forward-auth-headers.headers.customRequestHeaders = {
              "X-Forwarded-Proto" = "https";
              "X-Forwarded-Port" = "443";
            };

            services = lib.mkMerge (map mkHttpService enabledDmz);
            routers = lib.mkMerge (map (mkHttpRouter "dmz") enabledDmz);
          };
        };
      };
    };
  };
}
