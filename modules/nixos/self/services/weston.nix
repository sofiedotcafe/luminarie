{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

let
  cfg = config.services.weston.kiosk;
in
{
  options.services.weston.kiosk = {
    enable = mkEnableOption "Weston kiosk shell service";

    user = mkOption {
      type = types.str;
      default = "demo";
      description = "User to log in as.";
    };

    extraArguments = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra command-line arguments for Weston.";
    };

    program = mkOption {
      type = types.path;
      default = "";
      description = "Program to run in Weston kiosk shell.";
    };

    environment = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Environment variables for Weston.";
    };

    package = mkPackageOption pkgs "weston" { };
  };

  config = mkIf cfg.enable {
    systemd = {
      services."weston-tty1" = {
        enable = true;
        after = [
          "systemd-user-sessions.service"
          "systemd-logind.service"
          "getty@tty1.service"
        ];
        before = [ "graphical.target" ];
        wantedBy = [ "graphical.target" ];
        conflicts = [ "getty@tty1.service" ];

        unitConfig.ConditionPathExists = "/dev/tty1";
        serviceConfig = {
          ExecStart = ''
            ${
              cfg.package.overrideAttrs (prev: {
                mesonFlags = prev.mesonFlags or [ ] ++ [ (lib.mesonBool "shell-kiosk" true) ];
              })
            }/bin/weston \
              --xwayland \
              --shell=kiosk \
              ${escapeShellArgs cfg.extraArguments} \
              -- ${toString cfg.program}
          '';
          User = cfg.user;
          TTYPath = "/dev/tty1";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";
          StandardInput = "tty-fail";
          StandardOutput = "journal";
          StandardError = "journal";
          PAMName = "weston";
        };
        inherit (cfg) environment;
      };
      targets.graphical.wants = [ "weston-tty1.service" ];
      defaultUnit = "graphical.target";
    };

    security.pam.services.weston.text = ''
      auth    required pam_unix.so nullok
      account required pam_unix.so
      session required pam_unix.so
      session required pam_env.so conffile=/etc/pam/environment readenv=0
      session required ${config.systemd.package}/lib/security/pam_systemd.so
    '';

    services = {
      seatd.enable = true;
      libinput.enable = true;
    };

    security.polkit.enable = true;
    hardware.opengl.enable = true;
  };

  meta.maintainers = with lib.maintainers; [ ];
}
