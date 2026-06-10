{
  fetchFromGitHub,
  writeText,
  variant ? "mocha",
}:

let
  src = fetchFromGitHub {
    owner = "CalfMoon";
    repo = "signal-desktop";
    rev = "main";
    hash = "sha256-dWT3hG2uGhwpNgGHjwVmzci68upUVe5ktoeaPrNZ3q8=";
  };
in
writeText "catppuccin-signal.css" (builtins.readFile (src + "/themes/catppuccin-${variant}.css"))
