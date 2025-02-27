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
  version = "133";
in
lib.checkListOfEnum "${pname}: input theme variable has wrong type" [ "path" "null" ]
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
      hash = "sha256-k7v5PE6OcqMkC/u7aokwcxKDmTKM+ejiZGCsH9MK0s0=";
    };

    patchPhase = ''
      ${lib.optionalString (theme.dark != null) "cp -f ${theme.dark} ./theme/colors/dark.css"}
      ${lib.optionalString (theme.light != null) "cp -f ${theme.light} ./theme/colors/light.css"}
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
