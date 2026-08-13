{ self, ... }:

{
  perSystem =
    { pkgs, lib, ... }:
    let
      cfg = self.nixosConfigurations.tailstack.config;
      vault = cfg.modules.nixos.services.security.vault;

      schema = import ../modules/nixos/services/security/vault/secrets.nix {
        config = cfg;
        inherit lib;
        provisionSchemas = vault.provision or { };
      };

      spec = pkgs.writeText "main.tf.json" (builtins.toJSON schema);

      app = pkgs.writeShellScriptBin "tofu-vault" ''
        set -euo pipefail

        ln -sf "${spec}" ./main.tf.json
        exec ${pkgs.opentofu}/bin/tofu "$@"
      '';
    in
    {
      apps.default = {
        type = "app";
        program = lib.getExe app;
      };
    };
}
