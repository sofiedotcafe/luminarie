{
  src ? null,
  # Either 'server' or 'both' (to get client mods as well)
  side ? "both",
  # The derivation passes through a 'manifest' expression, that includes
  # useful metadata (such as MC version). When providing the manifest file itself,
  # this metadata can be used to automatically assign 'pname' and 'version'

  hash ? "",
  pkgs ? null,
  ...
}@args:
pkgs.stdenvNoCC.mkDerivation (
  finalAttrs:
  {
    inherit src;

    inherit (finalAttrs.passthru.manifest) version;
    pname = finalAttrs.passthru.manifest.name;

    buildInputs = with pkgs; [
      jre_headless
      jq
      moreutils
      curl
      cacert
      packwiz
    ];

    buildPhase =
      with pkgs;
      let
        packwiz-installer = fetchurl rec {
          pname = "packwiz-installer";
          version = "0.5.12";
          url = "https://github.com/packwiz/packwiz-installer/releases/download/v${version}/packwiz-installer.jar";
          hash = "sha256-IGgdxgkGqQG5fmWT0fVHFJQEqAjKNdL2v+DgLuJqRjs=";
        };
        packwiz-installer-bootstrap = fetchurl rec {
          pname = "packwiz-installer-bootstrap";
          version = "0.0.3";
          url = "https://github.com/packwiz/packwiz-installer-bootstrap/releases/download/v${version}/packwiz-installer-bootstrap.jar";
          hash = "sha256-qPuyTcYEJ46X9GiOgtPZGjGLmO/AjV2/y8vKtkQ9EWw=";
        };
      in
      ''
        packwiz refresh
        java -jar ${packwiz-installer-bootstrap} \
          --bootstrap-main-jar ${packwiz-installer} \
          --bootstrap-no-update \
          --no-gui \
          --side ${side}
        }"
      '';

    installPhase = ''
      runHook preInstall

      # Fix non-determinism
      rm env-vars -r
      jq -Sc '.' packwiz.json | sponge packwiz.json

      mkdir -p $out
      cp * -r $out/

      runHook postInstall
    '';

    passthru.manifest = pkgs.lib.importTOML "${src}/pack.toml";

    dontFixup = true;

    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = hash;
  }
  // args
)
