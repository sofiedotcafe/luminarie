{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      lib,
      system,
      pkgs,
      ...
    }:
    {
      overlayAttrs = {
        inherit (inputs.qt-decorations.packages.${system}) qcatppuccindecorations;
        inherit (inputs.nix-citizen.packages.${system}) rsi-launcher;

        blackbox-terminal = pkgs.blackbox-terminal.overrideAttrs (prev: {
          postInstall = (prev.postInstall or "") + ''
            substituteInPlace $out/share/applications/com.raggesilver.BlackBox.desktop \
              --replace "Exec=blackbox" "Exec=${lib.getExe (
                pkgs.writeShellScriptBin "blackbox-wrapper" ''
                  [ -f "$1" ] && set -- "$(dirname "$1")"
                  exec blackbox ''${1:+-w "$1"}
                ''
              )} %f"
            cat ${pkgs.writeText "com.raggesilver.BlackBox.desktop" ''
              MimeType=inode/directory;application/octet-stream;text/plain;image/*;video/*;audio/*;application/pdf;application/zip;
              X-AppInstall-Priority=low
            ''} >> $out/share/applications/com.raggesilver.BlackBox.desktop
          '';
        });
      }
      // (lib.listToAttrs (
        lib.mapAttrsToList
          (name: value: {
            name = { lix = "nix"; }.${name} or name;
            inherit value;
          })
          (
            lib.filterAttrs (
              name: value:
              lib.isDerivation value
              && lib.all (n: name != n) [
                "editline"
                "boehmgc"
              ]
            ) inputs.nixpkgs.legacyPackages.${system}.lixPackageSets.git
          )
      ));
    };
}
