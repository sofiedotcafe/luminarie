{
  lib,
  config,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.services.klipper;
in
{
  options.modules.nixos.services.klipper = {
    enable = mkEnableOption "all klipper services (incl. moonraker and fluidd)";

    plugins = mkOption {
      type = types.listOf types.path;
      default = [
        "${
          pkgs.fetchFromGitHub {
            owner = "protoloft";
            repo = "klipper_z_calibration";
            rev = "9f16ebc010e117ae81f9402fba90ed8c523726ae";
            sha256 = "sha256-YNy3FmDa4kksweWrhnwa6WKQR3sDoBxtnGh9BoXEIGs=";
          }
        }/z_calibration.py"
      ];
    };

    fluidd.enable = mkEnableOption "fluidd" // {
      default = true;
    };

    klipperscreen.enable = mkEnableOption "klipperscreen" // {
      default = true;
    };

    configuration = mkOption {
      type = types.mkOptionType {
        name = "directory";
        check = filesystem.pathIsDirectory;
      };
    };
  };
  config = mkIf cfg.enable {
    users = {
      groups.klipper.gid = 982;
      users.klipper = {
        uid = 982;
        group = "klipper";
        extraGroups = [
          "video"
          "input"
          "render"
          "seat"
        ];
        home = "/var/lib/klipper";
        isSystemUser = true;
      };
    };

    networking.firewall.allowedTCPPorts = [
      80
      7125
    ];

    services = {
      fluidd.enable = cfg.fluidd.enable;
      moonraker = {
        enable = true;
        user = "klipper";
        group = "klipper";
        address = "0.0.0.0";

        allowSystemControl = true;

        settings = {
          history = { };
          octoprint_compat = { };
          file_manager = {
            enable_object_processing = false;
            check_klipper_config_path = false;
          };
          data_store = {
            temperature_store_size = 600;
            gcode_store_size = 1000;
          };
          authorization = {
            force_logins = true;
            cors_domains = [
              "*://app.fluidd.xyz"
            ];
            trusted_clients = [
              "10.0.0.0/8"
              "127.0.0.0/8"
              "::1/128"
            ];
          };
        };
      };

      klipper = {
        enable = true;

        package = pkgs.klipper.overrideAttrs (
          _: prev: {
            installPhase = prev.installPhase + ''
              chmod -R u+w $out/lib/klippy && rm -r $out/lib/klippy

              ${builtins.concatStringsSep "\n" (
                map (plugin: "install -D ${plugin} $out/lib/klipper/extras/") cfg.plugins
              )}
            '';
          }
        );

        user = "klipper";
        group = "klipper";

        mutableConfig = true;
        logFile = "${config.services.klipper.mutableConfigFolder}/klipper.log";
        configFile = builtins.toFile "printer.cfg" (
          builtins.concatStringsSep "\n\n" (
            map (f: builtins.readFile f) (lib.filesystem.listFilesRecursive cfg.configuration)
          )
        );
      };

      cage = lib.mkIf cfg.klipperscreen.enable {
        enable = true;
        user = "klipper";
        program = "${lib.getExe pkgs.klipperscreen}";
        environment = {
          HOME = "/var/lib/klipper";
          WLR_DRM_DEVICES = "/dev/dri/card1";
          WLR_EGL_PLATFORM = "drm";
          WLR_LIBINPUT_NO_DEVICES = "1";
        };
      };

      seatd.enable = cfg.klipperscreen.enable;
      libinput.enable = cfg.klipperscreen.enable;
    };

    systemd.services = {
      moonraker.script = lib.mkForce ''
        config_path="${config.services.moonraker.stateDir}/config"
        mkdir -p $(basename "$config_path") && rm -rf $config_path
        ln -s "${config.services.klipper.mutableConfigFolder}" "$config_path"

        chown -R klipper:klipper "$config_path"
        chmod -R u+rwX "$config_path"/*
        chmod u+w "$config_path"/*

        rm -rf "$config_path"/gcodes

        cp -n /etc/moonraker.cfg "$config_path/moonraker.cfg"
        exec "${config.services.moonraker.package}/bin/moonraker" -d "${config.services.moonraker.stateDir}" -c "$config_path/moonraker.cfg"
      '';
    };
  };
}
