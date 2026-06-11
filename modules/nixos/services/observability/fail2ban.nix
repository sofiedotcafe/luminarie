{
  config,
  lib,
  ...
}:

let
  cfg = config.modules.nixos.services.observability.fail2ban;

  jails = {
    sshd = {
      enabled = true;
      settings = {
        filter = "sshd";
        logpath = "journalctl";
        backend = "systemd";
        maxretry = 5;
        findtime = 600;
        bantime = 3600;
      };
    };

    traefik-auth = {
      enabled = true;
      settings = {
        filter = "traefik-auth";
        logpath = "/var/log/traefik/access.log";
        maxretry = 5;
        findtime = 600;
        bantime = 3600;
      };
    };

    traefik-404 = {
      enabled = true;
      settings = {
        filter = "traefik-404";
        logpath = "/var/log/traefik/access.log";
        maxretry = 20;
        findtime = 300;
        bantime = 3600;
      };
    };

    traefik-badbots = {
      enabled = true;
      settings = {
        filter = "nginx-badbots";
        logpath = "/var/log/traefik/access.log";
        maxretry = 1;
        bantime = 7200;
      };
    };

    traefik-acme = {
      enabled = true;
      settings = {
        filter = "letsencrypt";
        logpath = "/var/log/traefik/traefik.log";
        maxretry = 3;
        bantime = 86400;
      };
    };

    traefik-rate-limit = {
      enabled = true;
      settings = {
        filter = "traefik-limit-req";
        logpath = "/var/log/traefik/traefik.log";
        maxretry = 50;
        findtime = 60;
        bantime = 600;
      };
    };

    systemd-auth = {
      enabled = true;
      settings = {
        filter = "systemd-auth";
        logpath = "journalctl";
        backend = "systemd";
        maxretry = 5;
        bantime = 3600;
      };
    };

    recidive = {
      enabled = true;
      settings = {
        filter = "recidive";
        logpath = "/var/log/fail2ban.log";
        bantime = 604800;
        findtime = 86400;
        maxretry = 5;
      };
    };
  };

in
{
  options.modules.nixos.services.observability.fail2ban = {
    enable = lib.mkEnableOption "Fail2ban intrusion prevention for a Traefik DMZ host";

    ignoreIPs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "127.0.0.1/8"
        "10.0.0.0/8"
      ];
    };

    banaction = lib.mkOption {
      type = lib.types.str;
      default = "iptables-multiport";
    };

    jails = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = true;
            };
            settings = lib.mkOption {
              type = lib.types.attrs;
              default = { };
            };
          };
        }
      );
      default = { };
    };

    daemonSettings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {

    services.fail2ban = {
      enable = true;
      ignoreIP = cfg.ignoreIPs;
      banaction = cfg.banaction;

      daemonSettings = lib.recursiveUpdate {
        DEFAULT = {
          bantime = 3600;
          findtime = 600;
          maxretry = 5;

          # GDPR‑safe aggressive logging
          loglevel = "DEBUG";
          logtarget = "/var/log/fail2ban.log";
          dbpurgeage = 86400; # 1 day retention
        };
      } cfg.daemonSettings;

      jails = lib.mapAttrs (_: jail: {
        enabled = jail.enabled;
        settings = jail.settings;
      }) (lib.recursiveUpdate jails cfg.jails);
    };

    systemd.tmpfiles.rules = [
      "d /var/log/traefik 0755 root root -"
      "f /var/log/fail2ban.log 0640 root root -"
    ];

    environment.etc = {
      "fail2ban/filter.d/traefik-auth.conf".text = ''
        [Definition]
        failregex = ^<HOST> .* "(GET|POST).*" 401
      '';

      "fail2ban/filter.d/traefik-404.conf".text = ''
        [Definition]
        failregex = ^<HOST> .* "(GET|POST).*" 404
      '';

      "fail2ban/filter.d/traefik-limit-req.conf".text = ''
        [Definition]
        failregex = ^.*client_ip=<HOST>.*rate limit exceeded.*
      '';

      "fail2ban/filter.d/letsencrypt.conf".text = ''
        [Definition]
        failregex = ^.*client_ip=<HOST>.*(Unable to obtain ACME certificate|error: one or more domains had a problem).*
      '';
    };
  };
}
