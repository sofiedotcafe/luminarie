{ inputs, self, ... }:
{
  imports = [
    inputs.nix-topology.flakeModule
  ];

  perSystem =
    {
      lib,
      config,
      system,
      ...
    }:
    {
      topology.modules = [
        (
          { config, ... }:
          let
            inherit (config.lib.topology)
              mkRouter
              mkSwitch
              mkConnection
              mkDevice
              ;
          in
          {
            inherit (self) nixosConfigurations;

            networks.native-lan = {
              name = "Native LAN";
              cidrv4 = "10.0.1.1/24";
            };

            networks.client = {
              name = "Client";
              cidrv4 = "10.0.98.1/24";
            };

            networks.quest = {
              name = "Guest WiFi";
              cidrv4 = "10.0.99.1/24";
            };

            networks.dmz = {
              name = "DMZ";
              cidrv4 = "10.0.1.1/31";
            };

            networks.infra = {
              name = "Infra";
              cidrv4 = "10.0.0.1/29";
            };

            nodes.internet = {
              name = "Internet";
              deviceType = "internet";
              hardware.image = ./icons/isp.png;

              interfaces."*".physicalConnections = [
                {
                  node = "gateway";
                  interface = "wan1";
                }
              ];
            };

            nodes.gateway = mkRouter "Gateway" {
              info = "UniFi UXG‑Pro";
              image = ./icons/gateway-pro.png;

              interfaceGroups = [
                [
                  "lan1"
                  "lan2"
                ]
                [
                  "wan1"
                  "wan2"
                ]
              ];

              interfaces.lan1 = {
                addresses = [ "10.0.1.1" ];
                network = "native-lan";
              };

              interfaces.lan2.network = "native-lan";

              interfaces.wan1 = {
                network = "native-lan";
              };
              interfaces.wan2.network = "native-lan";

              connections.lan1 = mkConnection "switch-agg" "sfp0";
            };

            nodes.switch-agg = mkSwitch "Aggregation Switch" {
              info = "USW‑Aggregation (8× SFP+)";
              image = ./icons/usw-aggregation.png;

              interfaceGroups = [
                [
                  "sfp0"
                  "sfp1"
                  "sfp2"
                ]
              ];

              interfaces = {
                sfp0 = {
                  network = "native-lan";
                  addresses = [ "10.0.1.2" ];
                };
                sfp1 = {
                  network = "native-lan";
                };
                sfp2 = {
                  network = "infra";
                };
                sfp3 = {
                  network = "dmz";
                };
              };

              connections.sfp1 = mkConnection "switch-poe" "eth0";
              connections.sfp2 = mkConnection "tailstack" "eth0";
              connections.sfp3 = mkConnection "tailstack" "eth1";
            };

            nodes.switch-poe = mkSwitch "PoE Switch" {
              info = "USW-Lite-8-PoE";
              image = ./icons/usw-lite-8-poe.png;

              interfaceGroups = [
                [
                  "eth0"
                  "eth1"
                  "eth2"
                ]
              ];

              interfaces = {
                eth0 = {
                  network = "native-lan";
                  addresses = [ "10.0.1.4" ];
                };
                eth1 = {
                  network = "native-lan";
                };
                eth2 = {
                  network = "native-lan";
                };
                eth3 = {
                  network = "infra";
                };

              };

              connections.eth1 = mkConnection "ap_lr" "eth0";
              connections.eth3 = mkConnection "tailstack" "ipmi";
            };

            nodes.ap_lr = mkDevice "U6 Lite" {
              image = ./icons/u6-lite.png;

              interfaces.eth0 = {
                network = "native-lan";
                addresses = [ "10.0.1.6" ];
              };

              interfaces."wifi-client".network = "client";
              interfaces."wifi-quest".network = "quest";
            };

            nodes.cloudkey = mkDevice "Cloud Key Gen2+" {
              image = ./icons/cloudkey-gen2+.png;

              interfaces.eth0 = {
                network = "native-lan";
                addresses = [ "10.0.1.7" ];
                physicalConnections = [
                  {
                    node = "switch-poe";
                    interface = "eth2";
                  }
                ];
              };
            };
          }
        )
      ];
    };
}
