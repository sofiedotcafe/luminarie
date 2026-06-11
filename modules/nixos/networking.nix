{
  lib,
  config,
  ...
}:

let
  inherit (lib)
    mkOption
    mkEnableOption
    types
    mkIf
    mapAttrs
    mapAttrs'
    filterAttrs
    ;

  cfg = config.modules.nixos.networking;

  prefixFromNetwork =
    network:
    let
      parts = lib.take 3 (lib.splitString "." network);
    in
    builtins.concatStringsSep "." parts + ".";

in
{
  options.modules.nixos.networking = {
    enable = mkEnableOption "networking";

    wan = {
      slaves = mkOption {
        type = types.listOf types.str;
        default = [ "enp1s0f0" ];
      };

      enableLAG = mkOption {
        type = types.bool;
        default = builtins.length cfg.wan.slaves > 1;
      };

      uplink = mkOption {
        type = types.str;
        default = "bond0";
      };
    };

    zones = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            vlan = mkOption {
              type = types.nullOr types.int;
              default = null;
            };
            bridge = mkOption {
              type = types.str;
            };
            network = mkOption {
              type = types.str;
            };
            prefix = mkOption {
              type = types.int;
            };

            addr = mkOption {
              type = types.nullOr types.str;
              default = null;
            };

            dhcp = mkOption {
              type = types.bool;
              default = false;
            };

            gateway = mkOption {
              type = types.nullOr types.str;
              default = null;
            };

            isWan = mkEnableOption "wan interface";
          };
        }
      );

      default = {
        svc = {
          vlan = 100;
          bridge = "br-svc";
          network = "10.0.0.0";
          prefix = 28;
          addr = "10.0.0.2";
          dhcp = false;
          gateway = "10.0.0.1";
          isWan = true;
        };

        dmz = {
          vlan = 110;
          bridge = "br-dmz";
          network = "10.0.1.0";
          prefix = 28;
          addr = "10.0.1.2";
          dhcp = false;
          gateway = "10.0.1.1";
          isWan = false;
        };

        cnt = {
          vlan = null;
          bridge = "br-cnt";
          network = "10.0.255.0";
          prefix = 24;
          addr = "10.0.255.1";
          dhcp = false;
          gateway = "10.0.255.1";
          isWan = false;
        };

        "cnt-dmz" = {
          vlan = null;
          bridge = "br-cnt-dmz";
          network = "10.0.254.0";
          prefix = 24;
          addr = "10.0.254.1";
          dhcp = false;
          gateway = "10.0.254.1";
          isWan = false;
        };
      };
    };

    containerInterfaces = mkOption {
      type = types.attrsOf (
        types.submodule (
          { config, ... }:
          {
            options = {
              zone = mkOption {
                type = types.enum (lib.attrNames cfg.zones);
              };

              id = mkOption {
                type = types.int;
              };

              address = mkOption {
                type = types.str;
                readOnly = true;
                default =
                  let
                    zoneName = config.zone; # submodule’s own zone
                    id = config.id; # submodule’s own id
                    zoneCfg = cfg.zones.${zoneName}; # parent zone definition
                    base = prefixFromNetwork zoneCfg.network;
                  in
                  "${base}${toString id}";
              };

              proxy = mkOption {
                type = types.nullOr (
                  types.submodule {
                    options = {
                      enable = mkOption {
                        type = types.bool;
                        default = false;
                      };
                      port = mkOption {
                        type = types.nullOr types.int;
                        default = null;
                      };
                      subdomain = mkOption {
                        type = types.nullOr types.str;
                        default = null;
                      };
                      tls = mkOption {
                        type = types.bool;
                        default = true;
                      };
                    };
                  }
                );
                default = { };
              };
            };
          }
        )
      );
      default = { };
    };
  };
  config = mkIf cfg.enable (
    let
      useBond = cfg.wan.enableLAG;
      uplinkName = if useBond then cfg.wan.uplink else builtins.head cfg.wan.slaves;

      wanZones = (lib.attrValues (filterAttrs (_: z: z.isWan) cfg.zones));
      wanZone = builtins.head wanZones;

      vlanZones = filterAttrs (_: z: z.vlan != null) cfg.zones;

      vlanNameForZone =
        zoneName:
        let
          id = cfg.zones.${zoneName}.vlan;
        in
        "vl-${toString id}";

      computedContainerIfaces = mapAttrs (
        _: ct:
        let
          zone = cfg.zones.${ct.zone};
          base = prefixFromNetwork zone.network;
          ip = "${base}${toString ct.id}";
        in
        {
          inherit (ct) zone id;
          bridge = zone.bridge;
          address = ip;
          prefix = zone.prefix;
          gateway = zone.addr;
        }
      ) cfg.containerInterfaces;

    in
    {
      assertions = [
        {
          assertion = lib.length wanZones == 1;
          message = "Exactly one zone must have isWan = true.";
        }
        {
          assertion = lib.all (z: (!z.dhcp) || (z.addr != null)) (lib.attrValues cfg.zones);
          message = "If dhcp = true, addr must be set.";
        }
      ];

      networking = {
        useNetworkd = true;
        useDHCP = false;

        bonds = mkIf useBond {
          "${cfg.wan.uplink}" = {
            interfaces = cfg.wan.slaves;
            driverOptions = {
              mode = "802.3ad";
              miimon = "100";
              xmit_hash_policy = "layer3+4";
            };
          };
        };

        vlans = mapAttrs' (zoneName: z: {
          name = vlanNameForZone zoneName;
          value = {
            id = z.vlan;
            interface = uplinkName;
          };
        }) vlanZones;

        bridges = mapAttrs' (zoneName: z: {
          name = z.bridge;
          value = {
            interfaces = if z.vlan != null then [ (vlanNameForZone zoneName) ] else [ ];
          };
        }) cfg.zones;

        interfaces = mapAttrs' (_: z: {
          name = z.bridge;
          value =
            if z.dhcp then
              {
                DHCP = "ipv4";
                ipv4.addresses = [
                  {
                    address = z.addr;
                    prefixLength = z.prefix;
                  }
                ];
              }
            else
              {
                ipv4.addresses = [
                  {
                    address = z.addr;
                    prefixLength = z.prefix;
                  }
                ];
              };
        }) cfg.zones;

        nat.enable = true;

        nftables = {
          enable = true;

          tables.io-systemd-nat = {
            family = "ip";
            content = ''
              chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;

                oifname "br-svc" masquerade
                oifname "br-dmz" masquerade

                oifname "br-vpn" masquerade
              }
            '';
          };
        };

        firewall = {
          enable = true;
          allowedTCPPorts = [
            22
            80
            443
            53
          ];
          allowedUDPPorts = [ 53 ];
        };

        defaultGateway.address = wanZone.gateway;
        defaultGateway.interface = wanZone.bridge;

        nameservers = [ "127.0.0.1" ];
      };

      systemd.network.wait-online.enable = false;
      services.resolved.enable = false;

      services.dnscrypt-proxy = {
        enable = true;

        settings = {
          listen_addresses = [ "127.0.0.1:53" ] ++ map (z: "${z.gateway}:53") (lib.attrValues cfg.zones);

          server_names = [
            "cloudflare"
            "quad9-dnscrypt-ip4-filter-pri"
          ];

          forwarding_rules = builtins.toFile "forwarding-rules" ''
            lan ${wanZone.gateway}
            local ${wanZone.gateway}
            home.arpa ${wanZone.gateway}

            sofie.cafe ${wanZone.gateway}
          '';

          require_dnssec = true;
          require_nolog = true;
          require_nofilter = true;
        };
      };

      containers = mapAttrs (
        _: ct:
        let
          zone = cfg.zones.${ct.zone};
        in
        {
          privateNetwork = true;
          hostBridge = ct.bridge;
          localAddress = "${ct.address}/${toString ct.prefix}";
          config = {
            services.resolved.enable = false;
            networking.nameservers = [ zone.gateway ];
            networking.useHostResolvConf = false;

            networking.defaultGateway = zone.gateway;

            networking.interfaces.eth0.ipv4 = {
              addresses = [
                {
                  address = ct.address;
                  prefixLength = ct.prefix;
                }
              ];

              routes = [
                {
                  address = "10.0.255.0";
                  prefixLength = 24;
                  via = ct.gateway;
                }
                {
                  address = "10.0.254.0";
                  prefixLength = 24;
                  via = ct.gateway;
                }
              ];
            };
          };
        }
      ) computedContainerIfaces;
    }
  );
}
