{ pkgs, ... }:

let
  pname = "haveno-reto";
  version = "1.2.0";

  src = pkgs.fetchurl {
    url = "https://github.com/retoaccess1/haveno-reto/releases/download/1.2.1-1/haveno-v1.2.0-linux-x86_64.AppImage";
    sha256 = "sha256-Ej9IdEi9IGgmRSf/0Ybw3oKfid0DleSGF4KIArrwTs4=";
  };
  appimageContents = pkgs.appimageTools.extract { inherit pname version src; };
in
pkgs.appimageTools.wrapType2 {
  inherit
    pname
    version
    src
    pkgs
    ;
  extraInstallCommands = ''
    install -m 444 -D ${appimageContents}/exchange.haveno.Haveno.desktop -t $out/share/applications
    install -m 444 -D ${appimageContents}/exchange.haveno.Haveno.svg $out/share/icons

    substituteInPlace $out/share/applications/exchange.haveno.Haveno.desktop \
      --replace 'Exec=AppRun' 'Exec=${pname}'
  '';

  extraBwrapArgs = [
    "--bind-try /etc/nixos/ /etc/nixos/"
  ];

  dieWithParent = false;
}
