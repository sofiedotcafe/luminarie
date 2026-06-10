{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  theme ? {
    dark = ./themes/catppuccin-mocha.css;
    light = null;
  },
}:
let
  pname = "firefox-gnome-theme";
  version = "143";
in
lib.checkListOfEnum "${pname}: input theme variable has wrong type" [ "path" "string" "null" ]
  (map (theme: builtins.typeOf theme) [
    theme.dark
    theme.light
  ])
  stdenvNoCC.mkDerivation
  rec {
    inherit pname version;
    src = fetchFromGitHub {
      owner = "rafaelmardojai";
      repo = "${pname}";
      rev = "v${version}";
      hash = "sha256-0E3TqvXAy81qeM/jZXWWOTZ14Hs1RT7o78UyZM+Jbr4=";
    };

    patchPhase = ''
      ${builtins.concatStringsSep "\n" (
        builtins.filter (x: x != "") (
          map (
            k:
            if theme.${k} != null then
              "cp -f ${
                if builtins.isString theme.${k} then ./themes/${theme.${k}}.css else theme.${k}
              } ./theme/colors/${k}.css"
            else
              ""
          ) (builtins.attrNames theme)
        )
      )}
    '';

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p $out
      cp -r ./* $out/
    '';

    meta = with lib; {
      description = "A GNOME theme for Firefox";
      homepage = "https://github.com/rafaelmardojai/firefox-gnome-theme";
      license = licenses.unlicense;
      platforms = platforms.all;
    };
  }
