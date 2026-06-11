{
  config,
  inputs,
  pkgs,
  ...
}:

{
  topology.self =
    let
      inherit (config.lib.topology) mkSwitch; # mkConnection
      mkNixos = name: args: mkSwitch name (args // { deviceType = "nixos"; });
    in
    mkNixos "Tailstack" {
      info = "SuperServer 828U / 829U Ultra";

      interfaces = {
        eth0 = {
          network = "infra";
          addresses = [ "10.0.0.2" ];
        };

        eth1 = {
          network = "dmz";
          addresses = [ "10.0.1.2" ];
        };

        ipmi = {
          network = "infra";
          addresses = [ "10.0.0.3" ];
        };
      };
    };

  topology.networks = {
    dmz = {
      name = "DMZ";
      cidrv4 = "10.0.1.1/28";
    };

    infra = {
      name = "Infra";
      cidrv4 = "10.0.0.1/28";
    };

    container = {
      name = "Containers";
      cidrv4 = "10.0.255.1/22";
    };
  };

  sops = {
    defaultSopsFile = "${inputs.self}/secrets/tailstack.yaml";

    secrets."users/root/password_hash" = { };
    secrets."users/root/password_hash".neededForUsers = true;

    secrets."traefik/cloudflare_acme_token" = { };

    secrets."grafana/secret_key" = { };
    secrets."grafana/client_secret" = { };

    secrets."authentik/secret_key" = { };
    secrets."authentik/smtp_key" = { };

    secrets."headscale/client_secret" = { };
    secrets."headscale/secret_key" = { };
  };

  users.users.root.hashedPasswordFile = config.sops.secrets."users/root/password_hash".path;
  services.userborn.enable = true;

  virtualisation.containers.enable = true;

  services.getty.autologinUser = "root";

  modules.nixos = {
    profile.minimal = {
      enable = true;
      hostName = "tailstack";
      ssh.allowRootLogin = true;
      ssh.allowPasswords = false;
    };

    language = {
      layout = "fi";
      time = "Europe/Helsinki";
    };

    networking = {
      enable = true;
    };

    services = {
      security = {
        authentik = {
          enable = true;
          email = {
            host = "smtp.protonmail.ch";
            username = "no-reply@sofie.cafe";
            from = "no-reply@sofie.cafe";
          };
        };
        tailscale.enable = true;
        vault.enable = true;
      };

      traefik = {
        enable = true;
        internalDomain = "cage.sofie.cafe";
        externalDomain = "sofie.cafe";
        acme.email = "sofie.halenius@sofie.cafe";
      };

      observability = {
        grafana.enable = true;
        prometheus.enable = true;

        loki.enable = true;
        alloy.enable = true;
        tempo.enable = true;

        fail2ban.enable = true;

        exporters = {
          node.enable = true;
          ipmi.enable = true;
          smart.enable = true;

          smart.devices = [
            "/dev/sda"
            "/dev/nvme0"
          ];
        };
      };
    };
  };
  services.journald.extraConfig = "Storage=persistent SystemMaxUse=200M ";

  boot.kernelParams = [
    "systemd.show_status=1"
    "systemd.log_level=info"
    "systemd.log_target=console"

    "kernel.kptr_restrict=2"
    "kernel.dmesg_restrict=1"
    "slab_nomerge"
    "page_poison=1"
    "pti=on"
    "spectre_v2=on"
    "spec_store_bypass_disable=on"

    "mds=full"
    "tsx_async_abort=full"
    "mmio_stale_data=full"
  ];

  services = {
    avahi.enable = false;
    printing.enable = false;
  };

  networking.firewall.allowPing = false;

  security = {
    protectKernelImage = true;
    lockKernelModules = false;
    allowSimultaneousMultithreading = false;
    auditd.enable = true;
  };

  systemd.coredump.enable = false;
  boot.kernel.sysctl."kernel.yama.ptrace_scope" = 2;

  services.openssh.enable = true;
  services.openssh.settings = {
    PasswordAuthentication = false;
    KbdInteractiveAuthentication = false;
    X11Forwarding = false;
    AllowTcpForwarding = "no";
    AllowAgentForwarding = "no";
    ClientAliveInterval = 30;
    ClientAliveCountMax = 2;
    LogLevel = "VERBOSE";
  };

  environment.systemPackages = with pkgs; [
    vim
    htop
    curl
    wget
    jq
  ];

  system.stateVersion = "26.05";
}
