{ inputs, ... }:
{
  imports = [ inputs.pre-commit-hooks.flakeModule ];

  perSystem =
    { config, pkgs, ... }:
    {
      pre-commit = {
        check.enable = true;
        settings.excludes = [ "flake.lock" ];
        settings.hooks = {
          nixfmt-rfc-style.enable = true;
          deadnix.enable = true;
          statix.enable = true;
        };
      };
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nixos-generators
          git
          just
        ];
        shellHook = ''
          ${config.pre-commit.installationScript}
        '';
      };
      formatter = pkgs.nixfmt-rfc-style;
    };
}
