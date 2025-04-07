{ inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    { pkgs, lib, ... }:
    {
      overlayAttrs = {
        catppuccin-qt5ct = pkgs.catppuccin-qt5ct.overrideAttrs (_: {
          src = pkgs.fetchFromGitHub {
            owner = "catppuccin";
            repo = "qt5ct";
            rev = "0442cc931390c226d143e3a6d6e77f819c68502a";
            sha256 = "hXyPuI225WdMuVSeX1AwrylUzNt0VA33h8C7MoSJ+8A=";
          };
        });
        blackbox-terminal = pkgs.blackbox-terminal.overrideAttrs (oldAttrs: {
          postInstall =
            (oldAttrs.postInstall or "")
            + ''
              substituteInPlace $out/share/applications/com.raggesilver.BlackBox.desktop \
                --replace "Exec=blackbox" "Exec=${lib.getExe (
                  pkgs.writeShellScriptBin "blackbox-wrapper" ''
                    exec blackbox ''${@:+-w "$@"}
                  ''
                )} %f"
              echo "MimeType=inode/directory;" >> $out/share/applications/com.raggesilver.BlackBox.desktop
            '';
        });
      };
    };
}
