{ inputs, ... }:
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      pre-commit = {
        check.enable = true;
        settings.excludes = [ "flake.lock" ];
        settings.hooks = {
          nixfmt.enable = true;
          deadnix.enable = true;
          # statix.enable = true;
        };
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          git
          yq
          jq
          age
          age-plugin-yubikey
          nixos-anywhere
          opentofu
          sops
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
      formatter = pkgs.nixfmt;
    };
}
