{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      pkgs,
      lib,
      system,
      ...
    }:
    {
      overlayAttrs = {
        inherit (inputs.qt-decorations.packages.${system}) qcatppuccindecorations;
        catppuccin-qt5ct = pkgs.catppuccin-qt5ct.overrideAttrs (_: {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "qt5ct";
            rev = "0442cc931390c226d143e3a6d6e77f819c68502a";
            sha256 = "hXyPuI225WdMuVSeX1AwrylUzNt0VA33h8C7MoSJ+8A=";
          };
        });
        blackbox-terminal = pkgs.blackbox-terminal.overrideAttrs (oldAttrs: {
          postInstall = (oldAttrs.postInstall or "") + ''
            substituteInPlace $out/share/applications/com.raggesilver.BlackBox.desktop \
              --replace "Exec=blackbox" "Exec=${lib.getExe (
                pkgs.writeShellScriptBin "blackbox-wrapper" ''
                  [ -f "$1" ] && set -- "$(dirname "$1")"
                  exec blackbox ''${1:+-w "$1"}
                ''
              )} %f"
            echo "MimeType=inode/directory;application/octet-stream;text/plain;image/*;video/*;audio/*;application/pdf;application/zip;" >> $out/share/applications/com.raggesilver.BlackBox.desktop
            echo "X-AppInstall-Priority=low" >> $out/share/applications/com.raggesilver.BlackBox.desktop
          '';
        });
      }
      // lib.listToAttrs (
        lib.mapAttrsToList
          (name: val: {
            name =
              let
                replacedNames = {
                  lix = "nix";
                };
              in
              if pkgs.lib.hasAttr name replacedNames then pkgs.lib.getAttr name replacedNames else name;
            value = val;
          })
          (
            lib.filterAttrs (
              _: v: lib.isDerivation v
            ) inputs.nixpkgs.legacyPackages.${system}.lixPackageSets.git
          )
      );
    };
}
