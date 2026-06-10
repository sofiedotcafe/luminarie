{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      lib,
      system,
      pkgs,
      self',
      ...
    }:
    {
      overlayAttrs = with pkgs; {
        nix = lixPackageSets.git.lix;

        inherit (inputs.qt-decorations.packages.${system}) qcatppuccindecorations;
        inherit (inputs.nix-citizen.packages.${system}) rsi-launcher;

        gnome-shell = pkgs.gnome-shell.overrideAttrs (prev: {
          postPatch = (prev.postPatch or "") + ''
            substituteInPlace js/ui/mpris.js \
              --replace "this._trackCoverUrl = metadata['mpris:artUrl'];" \
                        "const newCover = metadata['mpris:artUrl']; this._trackCoverUrl = (typeof newCover === 'string' && newCover.length > 0) ? newCover : this._trackCoverUrl;"
          '';
        });

        signal-desktop =
          (lib.makeOverridable (
            {
              theme ? null,
            }:
            signal-desktop.overrideAttrs (prev: {
              postPatch =
                (prev.postPatch or "")
                + (lib.throwIf (theme == null || builtins.typeOf theme != "string")
                  "signal-desktop: theme must be null or a string for a path (got ${builtins.typeOf theme})"
                  (
                    lib.optionalString (theme != null) ''
                      sed -i '1i @use "${theme}" as *;' stylesheets/manifest.scss
                    ''
                  )
                );
            })
          ))
            { };

        blackbox-terminal = blackbox-terminal.overrideAttrs (prev: {
          buildInputs = (
            lib.filter (pkg: pkg != pkgs.vte-gtk4) (
              prev.buildInputs
              ++ [
                self'.packages.vte-sixel
              ]
            )
          );

          postInstall = (prev.postInstall or "") + ''
            substituteInPlace $out/share/applications/com.raggesilver.BlackBox.desktop \
              --replace "Exec=blackbox" "Exec=${lib.getExe (
                writeShellScriptBin "blackbox-wrapper" ''
                  [ -f "$1" ] && set -- "$(dirname "$1")"
                  exec blackbox ''${1:+-w "$1"}
                ''
              )} %f"
            cat ${writeText "com.raggesilver.BlackBox.desktop" ''
              MimeType=inode/directory;application/octet-stream;text/plain;image/*;video/*;audio/*;application/pdf;application/zip;
              X-AppInstall-Priority=low
            ''} >> $out/share/applications/com.raggesilver.BlackBox.desktop
          '';
        });
      };
    };
}
