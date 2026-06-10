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

        publicKeys = mkOption {
          type = types.listOf types.str;
          default = [
            "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIJjRbVID3j7/Pvkp8P6saRlKxh2pqz7vK20pIYnMflfyAAAACXNzaDpzb2ZpZQ== sofie.halenius@sofie.cafe"
          ];
        };
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
      if cfg.initiallyDisableRoot then "!" else null
    );

    users.users.root.openssh.authorizedKeys.keys = cfg.ssh.publicKeys;

    security = {
      sudo.wheelNeedsPassword = cfg.interactiveSudo;
      polkit.enable = true;
      rtkit.enable = true;
    };

    networking = {
      inherit (cfg) hostName;
      hostId = builtins.substring 0 8 (builtins.hashString "sha256" cfg.hostName);
    };
  };
}
