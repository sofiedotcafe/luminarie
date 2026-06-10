{ config, lib, pkgs, ... }:

let
  cfg = config.modules.nixos.services.observability.alloy;

  loki  = config.modules.nixos.services.observability.loki;
  tempo = config.modules.nixos.services.observability.tempo;

  containers = builtins.attrNames config.containers;

  sanitize = name: lib.replaceStrings [ "-" ] [ "_" ] name;
  maybe = cond: str: if cond then str else "";
in
{
  options.modules.nixos.services.observability.alloy = {
    enable = lib.mkEnableOption "Grafana Alloy OTEL pipeline";

    httpPort     = lib.mkOption { type = lib.types.int; default = 12345; };
    otlpGrpcPort = lib.mkOption { type = lib.types.int; default = 4317; };
    otlpHttpPort = lib.mkOption { type = lib.types.int; default = 4318; };
  };

  config = lib.mkIf cfg.enable {

    services.alloy = {
      enable = true;

      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:${toString cfg.httpPort}"
      ];

      configPath = builtins.toFile "alloy" ''
otelcol.receiver.otlp "default" {
  grpc {
    endpoint = "0.0.0.0:${toString cfg.otlpGrpcPort}"
  }
  http {
    endpoint = "0.0.0.0:${toString cfg.otlpHttpPort}"
  }

  output {
    logs    = []
    metrics = []
    traces  = [ otelcol.processor.batch.traces.input ]
  }
}

loki.source.journal "host" {
  forward_to = [ loki.process.host.receiver ]
}

loki.source.file "host_files" {
  targets = [
    {
      __path__ = "/var/log/*log",
    },
  ]
  forward_to = [ loki.process.host.receiver ]
}

${lib.concatStringsSep "\n" (map (name:
  let safe = sanitize name;
  in ''
loki.source.journal "c_${safe}" {
  path = "/var/lib/nixos-containers/${name}/var/log/journal"
  labels = {
    container = "${name}",
  }
  forward_to = [ loki.process.containers.receiver ]
}

loki.source.file "c_${safe}_files" {
  targets = [
${lib.concatStringsSep ",\n" [
  "    { __path__ = \"/var/lib/nixos-containers/${name}/var/log/*log\", container = \"${name}\" },"
]}
  ]
  forward_to = [ loki.process.containers.receiver ]
}
''
) containers)}

${maybe loki.enable ''
loki.process "host" {
  forward_to = [ loki.write.default.receiver ]
}

loki.process "containers" {
  forward_to = [ loki.write.default.receiver ]
}

loki.write "default" {
  endpoint {
    url = "http://${loki.address}:${toString loki.port}/loki/api/v1/push"
  }
}
''}

${maybe (!loki.enable) ''
loki.process "host"       { forward_to = [] }
loki.process "containers" { forward_to = [] }
''}

otelcol.processor.batch "traces" {
  timeout = "5s"
  output {
    traces = [
${if tempo.enable then "      otelcol.exporter.otlp.tempo.input," else ""}
    ]
  }
}

${maybe tempo.enable ''
otelcol.exporter.otlp "tempo" {
  client {
    endpoint = "http://${tempo.address}:${toString tempo.otlpPort}"
    tls { insecure = true }
  }
}
''}
      '';
    };

    systemd.services.alloy = {
      serviceConfig = {
        SupplementaryGroups = [ "systemd-journal" ];

        ReadOnlyPaths = [
          "/var/lib/nixos-containers"
        ];
      };
    };
  };
}
