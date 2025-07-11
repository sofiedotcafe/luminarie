{
  lib,
  stdenv,
  autoPatchelfHook,
  dpkg,
  fetchurl,
  libcxx,
  pcscliteWithPolkit,
  imagemagick,
  copyDesktopItems,
  makeDesktopItem,
  qt6,
  qpdf,
}:
stdenv.mkDerivation rec {
  pname = "atostekid";
  version = "4.3.1.0";

  src = fetchurl rec {
    url = "https://dvv.fi/documents/16079645/237937167/AtostekID_DEB_${version}.deb";
    sha256 = "sha256-3cZWbv5x+NT/GrW6sVr5b5ew0w7FpDvKVsVi+UXeHDA=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    qt6.wrapQtAppsHook
    copyDesktopItems
    imagemagick
    dpkg
  ];

  buildInputs = [
    libcxx
    pcscliteWithPolkit.lib
    qt6.qtbase
    qt6.qtwebengine
    qpdf.lib
  ];

  qtWrapperArgs = [ "--prefix LD_LIBRARY_PATH : ${placeholder "out"}/lib/" ];

  unpackPhase = ''
    runHook preUnpack
    dpkg -x $src source
    cd source
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall
    mkdir $out

    cp -r usr/* $out/

    runHook postInstall
  '';

  postInstall = ''
    for size in 16 24 32 48 64 128 256 512; do
        mkdir -p $out/share/icons/hicolor/"$size"x"$size"/apps
        magick -background none ${./logo.png} -resize "$size"x"$size" $out/share/icons/hicolor/"$size"x"$size"/apps/atostekid.png
      done
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "Atostek ID";
      desktopName = "Atostek ID";
      icon = "atostekid";
      comment = meta.description;
      exec = "atostekid";
      type = "Application";
      terminal = false;
      categories = [
        "Utility"
        "Security"
      ];
    })
  ];

  meta = {
    description = "Official DVV card reader software by Atostek for authentication and digital signatures.";
    mainProgram = "atostekid";
    homepage = "https://dvv.fi/en/card-reader-software";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
  };
}
