{ lib, ... }:

{
  options.modules.nixos.services.security.vault = {
    provision = lib.mkOption {
      default = { };
      description = "Declarative schema specifications per application.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            policy = lib.mkOption {
              type = lib.types.attrsOf lib.types.str;
              default = { };
            };

            vault = {
              kv = lib.mkOption {
                type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
                default = { };
              };

              approle = {
                policies = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                };

                bootstrap = lib.mkOption {
                  type = lib.types.bool;
                  default = false;
                };
              };
            };
          };
        }
      );
    };
  };
}
