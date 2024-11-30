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
            installPhase =
              prev.installPhase
              + ''
                # Nixpkgs patches the Klipper library files to use Python 3 instead of Python 2. 
                # During this process, the directory is renamed from /lib/klippy to /lib/klipper. 
                # However, the unpatched /lib/klippy folder remains in the output derivation, which should be removed.
                # Though, due to some unknown permission issues, you need to make it writable first.
                chmod -R u+w $out/lib/klippy
                rm -r $out/lib/klippy

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
    };

    systemd.services = {
      # This might not be the ideal approach, but it avoids the need to fork the repository for this minor adjustment (e.g. removing the line that creates /var/lib/klipper/gcodes).
      klipper.preStart =
        let
          cfg = config.services.klipper;
          format = pkgs.formats.ini {
            # https://github.com/NixOS/nixpkgs/pull/121613#issuecomment-885241996
            listToValue =
              l:
              if builtins.length l == 1 then
                lib.generators.mkValueStringDefault { } (lib.head l)
              else
                lib.concatMapStrings (s: "\n  ${lib.generators.mkValueStringDefault { } s}") l;
            mkKeyValue = lib.generators.mkKeyValueDefault { } ":";
          };
          printerConfigPath =
            if cfg.mutableConfig then cfg.mutableConfigFolder + "/printer.cfg" else "/etc/klipper.cfg";
          printerConfigFile =
            if cfg.settings != null then format.generate "klipper.cfg" cfg.settings else cfg.configFile;
        in
        lib.mkForce ''
          mkdir -p ${cfg.mutableConfigFolder}
          ${lib.optionalString cfg.mutableConfig ''
            [ -e ${printerConfigPath} ] || {
              cp ${printerConfigFile} ${printerConfigPath}
              chmod +w ${printerConfigPath}
            }
          ''}
        '';

      moonraker.script = lib.mkForce ''
        config_path="${config.services.moonraker.stateDir}/config"

        mkdir -p $(basename "$config_path")

        echo $config_path      
        rm -rf $config_path && ln -s "${config.services.klipper.mutableConfigFolder}" "$config_path"

        chmod u+w "$config_path"
        cp -n /etc/moonraker.cfg "$config_path/moonraker.cfg"
        exec "${config.services.moonraker.package}/bin/moonraker" -d "${config.services.moonraker.stateDir}" -c "$config_path/moonraker.cfg"
      '';
    };
  };
}
