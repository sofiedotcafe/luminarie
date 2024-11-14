{
  config,
  pkgs,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.shell;
in
{
  config = mkIf (cfg.package == pkgs.zsh) {
    programs = {
      zsh = {
        enable = true;
        initExtra = getExe cfg.fetcher.package;

        syntaxHighlighting.enable = true;
        autosuggestion.enable = true;
        oh-my-zsh = {
          enable = true;
          plugins = [ "git" ];
        };
      };

      starship = {
        enable = true;
        enableZshIntegration = true;
        settings = {
          custom.mommy = {
            command =
              # Mommy loves her sweetie~ <3
              # She wants to make sure that her sweetie is always with her~

              # The option `mommySettings` for the package `mommy` does not work with the recent versions of `mommy`.
              # This is because the `mommy` package does not support the `MOMMY_OPT_CONFIG_FILE` environment variable anymore. oopsie~ >.<
              # So, we have to use the `--add-flags` option to pass the configuration file to `mommy`.

              # Waiting for nixpkgs to update the package definiton for `mommy` to support the new `-c` variable.

              let
                variables = lib.mapAttrs' (name: value: nameValuePair "MOMMY_${lib.toUpper name}" value) {
                  sweetie = "Sofie";
                  color = "";
                };
                configFile = pkgs.writeText "mommy-config" (toShellVars variables);
              in
              "${
                lib.getExe (
                  pkgs.mommy.overrideAttrs {
                    postInstall = ''
                      wrapProgram $out/bin/mommy \
                        --add-flags "-c ${configFile}"
                    '';
                  }
                )
              } -1";
            style = "bold pink";
            when = "true";
          };

          format = concatStrings [
            "$all"
            "$fill"
            "\${custom.mommy}"
            "$line_break"
            "$jobs"
            "$battery"
            "$time"
            "$status"
            "$os"
            "$container"
            "$shell"
            "$character"
          ];

          fill = {
            symbol = " ";
          };
        };
      };

      direnv = {
        enable = true;
        enableZshIntegration = true;
        nix-direnv.enable = true;
      };
    };
  };
}
