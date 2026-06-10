{ config, lib, inputs, pkgs, ... }:

let
  cfg = config.modules.nixos.services.traefik;
  net = config.modules.nixos.networking;

  enabled =
    lib.filterAttrs (_: iface:
      iface.proxy != null &&
      iface.proxy.enable &&
      iface.proxy.subdomain != null &&
      iface.proxy.port != null
    ) net.containerInterfaces;

  isDmz = iface: lib.hasInfix "dmz" (lib.toLower iface.zone);

  enabledInternal = lib.filterAttrs (_: iface: !isDmz iface) enabled;
  enabledDmz      = lib.filterAttrs (_: iface:  isDmz iface) enabled;

  prefixFromAddr = addr:
    let parts = lib.take 3 (lib.splitString "." addr);
    in builtins.concatStringsSep "." parts + ".";

  containerIp = name: iface:
    let
      zone = net.zones.${iface.zone};
      base = prefixFromAddr zone.addr;
    in "${base}${toString iface.id}";

  domainFor = iface:
    if isDmz iface
    then cfg.externalDomain
    else cfg.internalDomain;

  mkService = target: name: iface: {
    "${iface.proxy.subdomain}".loadBalancer.servers = [
      { url = "http://${containerIp name iface}:${toString iface.proxy.port}"; }
    ];
  };

  mkRouter = target: name: iface: {
    "${iface.proxy.subdomain}" = {
      rule = "Host(`${iface.proxy.subdomain}.${domainFor iface}`)";
      entryPoints = [ "websecure" ];
      service = iface.proxy.subdomain;

      tls = lib.mkIf iface.proxy.tls {
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

    networking.firewall.allowedTCPPorts = [ 80 443 ];

    # Host-side dirs only, root-owned
    systemd.tmpfiles.rules = [
      "d /var/acme 0755 root root -"
      "d /var/log/traefik 0755 root root -"
    ];

    sops.templates."traefik-env".content =
      ''CF_DNS_API_TOKEN="${config.sops.placeholder."traefik/cloudflare_acme_token"}"'';

    containers.traefik = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = net.zones.svc.bridge;

      bindMounts.${cfg.acme.storage} = {
        hostPath = cfg.acme.storage;
        isReadOnly = false;
      };

      bindMounts.${config.sops.templates."traefik-env".path} = {
        hostPath = config.sops.templates."traefik-env".path;
        isReadOnly = true;
      };

      bindMounts."/var/log/traefik" = {
        hostPath = "/var/log/traefik";
        isReadOnly = false;
      };

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        systemd.tmpfiles.rules = [
          "d /var/acme 0755 traefik traefik -"
          "f /var/acme/internal.json 0600 traefik traefik -"
          "d /var/log/traefik 0755 traefik traefik -"
          "f /var/log/traefik/access.log 0644 traefik traefik -"
          "f /var/log/traefik/traefik.log 0644 traefik traefik -"
        ];

        systemd.services.traefik.serviceConfig = {
          EnvironmentFile = config.sops.templates."traefik-env".path;
          LimitNPROC = lib.mkForce 4096;
          LimitNPROCSoft = lib.mkForce 4096;
        };

        networking.firewall.allowedTCPPorts = [ 80 443 ];

        services.traefik = {
          enable = true;

          staticConfigOptions = {
            log = { level = "DEBUG"; };
            accessLog = { bufferingSize = 0; fields.defaultMode = "keep"; };

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
              "X-Forwarded-Port"  = "443";
            };

            services = lib.mkMerge (lib.mapAttrsToList (mkService "internal") enabledInternal);
            routers  = lib.mkMerge (lib.mapAttrsToList (mkRouter  "internal") enabledInternal);
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

      bindMounts.${cfg.acme.storage} = {
        hostPath = cfg.acme.storage;
        isReadOnly = false;
      };

      bindMounts.${config.sops.templates."traefik-env".path} = {
        hostPath = config.sops.templates."traefik-env".path;
        isReadOnly = true;
      };

      bindMounts."/var/log/traefik" = {
        hostPath = "/var/log/traefik";
        isReadOnly = false;
      };

      config = {
        imports = [ inputs.nix-topology.nixosModules.default ];
        system.stateVersion = "26.05";

        networking.firewall.allowedTCPPorts = [ 80 443 ];

        systemd.tmpfiles.rules = [
          "d /var/acme 0755 traefik traefik -"
          "f /var/acme/external.json 0600 traefik traefik -"
          "d /var/log/traefik 0755 traefik traefik -"
          "f /var/log/traefik/access.log 0644 traefik traefik -"
          "f /var/log/traefik/traefik.log 0644 traefik traefik -"
        ];

        systemd.services.traefik.serviceConfig = {
          EnvironmentFile = config.sops.templates."traefik-env".path;
          LimitNPROC = lib.mkForce 4096;
          LimitNPROCSoft = lib.mkForce 4096;
        };

        services.traefik = {
          enable = true;

          staticConfigOptions = {
            log = { level = "DEBUG"; };
            accessLog = { bufferingSize = 0; fields.defaultMode = "keep"; };

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
              "X-Forwarded-Port"  = "443";
            };

            services = lib.mkMerge (lib.mapAttrsToList (mkService "dmz") enabledDmz);
            routers  = lib.mkMerge (lib.mapAttrsToList (mkRouter  "dmz") enabledDmz);
          };
        };
      };
    };
  };
}
