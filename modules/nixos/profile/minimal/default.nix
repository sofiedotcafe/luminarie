{
  lib,
  config,
  ...
}:
with lib;
let
  cfg = config.modules.nixos.profile.minimal;
in
{
  options.modules.nixos.profile = {
    minimal = {
      enable = mkEnableOption "minimal";
      hostName = mkOption {
        type = types.str;
        default = "minimal";
      };

      interactiveSudo = mkEnableOption "interactive sudo" // {
        default = true;
      };

      initiallyDisableRoot = mkEnableOption "initially disable root";

      ssh = {
        allowPasswords = mkEnableOption "authentication with passwords";
        allowRootLogin = mkEnableOption "allow root login";
      };
    };
  };
  config = mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = cfg.ssh.allowPasswords;
        PermitRootLogin = if cfg.ssh.allowRootLogin then "yes" else "no";
      };
    };

    users.users.root.initialHashedPassword = lib.mkDefault (
      if cfg.initiallyDisableRoot then "!" else ""
    );

    security = {
      sudo.wheelNeedsPassword = cfg.interactiveSudo;
      polkit.enable = true;
      rtkit.enable = true;
    };

    networking = {
      inherit (cfg) hostName;
      networkmanager.enable = true;
    };

    # https://discussion.fedoraproject.org/t/wpa-supplicant-logs/134579
    systemd.services.wpa_supplicant.serviceConfig.LogLevelMax = 4;
  };
}
