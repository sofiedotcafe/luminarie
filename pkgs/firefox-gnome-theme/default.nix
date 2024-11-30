{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  theme ? "catppuccin-mocha",
}:

let
  pname = "firefox-gnome-theme";
  version = "129";
in

lib.checkListOfEnum "${pname}: selected theme" [ "catppuccin-mocha" ] [ theme ]
  stdenvNoCC.mkDerivation
  {
    inherit pname version;
    src = fetchFromGitHub {
      owner = "rafaelmardojai";
      repo = "${pname}";
      rev = "v${version}";
      hash = "sha256-MOE9NeU2i6Ws1GhGmppMnjOHkNLl2MQMJmGhaMzdoJM=";
    };

    patches = [ ./themes/${theme}.patch ];

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
