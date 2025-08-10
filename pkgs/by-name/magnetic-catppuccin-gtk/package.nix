{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchpatch,
  gtk-engine-murrine,
  jdupes,
  sassc,
  accent ? [ "default" ],
  shade ? "dark",
  size ? "standard",
  tweaks ? [ ],
}:
let
  validAccents = [
    "default"
    "rosewater"
    "flamingo"
    "pink"
    "mauve"
    "red"
    "maroon"
    "peach"
    "yellow"
    "green"
    "teal"
    "sky"
    "sapphire"
    "blue"
    "lavender"
    "grey"
    "all"
  ];
  validShades = [
    "light"
    "dark"
  ];
  validSizes = [
    "standard"
    "compact"
  ];
  validTweaks = [
    "frappe"
    "macchiato"
    "black"
    "float"
    "outline"
    "macos"
  ];

  single = x: lib.optional (x != null) x;
  pname = "Catppuccin-GTK";
in
lib.checkListOfEnum "${pname} Valid theme accent(s)" validAccents accent lib.checkListOfEnum
  "${pname} Valid shades"
  validShades
  (single shade)
  lib.checkListOfEnum
  "${pname} Valid sizes"
  validSizes
  (single size)
  lib.checkListOfEnum
  "${pname} Valid tweaks"
  validTweaks
  tweaks

  stdenv.mkDerivation
  {
    pname = "magnetic-${lib.toLower pname}";
    version = "0-unstable-2025-08-06";

    src = fetchFromGitHub {
      owner = "Fausto-Korpsvart";
      repo = "Catppuccin-GTK-Theme";
      rev = "7e1ae7882a288ed5b80ddf58c1847c290615075c";
      hash = "sha256-FFVUVtLS7XpTVo4/pSEpUh759y/SkkksS1UC25yFor4=";
    };

    patches = [
      (fetchpatch {
        url = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme/pull/62.patch";
        hash = "sha256-5j2S9QJ9AuY2yegsuwPm9sPaS7DkGZiydbkEcs6JTtE=";
      })
    ];

    nativeBuildInputs = [
      jdupes
      sassc
    ];

    propagatedUserEnvPkgs = [ gtk-engine-murrine ];

    postPatch = ''
      find -name "*.sh" -print0 | while IFS= read -r -d ''' file; do
        patchShebangs "$file"
      done
    '';

    dontBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/share/themes

      ./themes/install.sh \
        --name ${pname} \
        ${toString (map (x: "--theme " + x) accent)} \
        ${lib.optionalString (shade != null) ("--color " + shade)} \
        ${lib.optionalString (size != null) ("--size " + size)} \
        ${toString (map (x: "--tweaks " + x) tweaks)} \
        --dest $out/share/themes

      jdupes --quiet --link-soft --recurse $out/share

      for dir in $out/share/themes/*/gnome-shell; do
        assets=$(find "$dir" -type f)

        cat <<EOF > "$dir/gnome-shell-theme.gresource.xml"
      <gresources>
        <gresource prefix="/org/gnome/shell/theme">
      EOF

        for file in $assets; do
          relpath="''${file#$dir/}"
          echo "    <file>$relpath</file>" >> "$dir/gnome-shell-theme.gresource.xml"
        done

        cat <<EOF >> "$dir/gnome-shell-theme.gresource.xml"
        </gresource>
      </gresources>
      EOF
      done

      runHook postInstall
    '';

    meta = with lib; {
      description = "GTK Theme with Catppuccin colour scheme";
      homepage = "https://github.com/Fausto-Korpsvart/Catppuccin-GTK-Theme";
      license = licenses.gpl3Only;
      maintainers = with maintainers; [ icy-thought ];
      platforms = platforms.all;
    };
  }
