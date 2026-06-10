{
  pkgs,
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.modules.home.programs.vesktop;
in
{
  options.modules.home = {
    programs.vesktop = {
      enable = mkEnableOption "vesktop";
      mprisence.enable = mkEnableOption "vesktop" // {
        default = true;
      };
    };
  };

  config = mkIf cfg.enable {
    programs.vesktop = {
      enable = true;

      settings = {
        arRPC = true;
        hardwareAcceleration = true;
        minimizeToTray = true;
        discordBranch = "stable";
      };

      vencord.useSystem = true;

      vencord.settings.plugins = {
        FakeNitro = {
          enabled = true;
          enableStreamQualityBypass = false;
        };
        FakeProfileThemes.enabled = true;
        USBRG.enabled = true;

        CustomSounds = {
          enabled = true;

          discodo = {
            enabled = true;
            selectedSound = "custom";
            volume = 100;
            selectedFileId = "c37644c5de7d45de28ce6040d442393a7be13f1f0e2ff06dd9b45f09c785bac7";
          };
        }
        // builtins.listToAttrs (
          map
            (name: {
              inherit name;
              value = {
                enabled = true;
                selectedSound = "custom";
                volume = 100;
                selectedFileId = "9d2007e21860ea9ace42ed96ec5c4c70cdb917cfebdbecf47e547b8b2e0ef01f";
              };
            })
            [
              "mention1"
              "mention2"
              "mention3"
              "message1"
              "message2"
              "message3"
            ]
        );
        AlwaysAnimate.enabled = true;
      };

      package = pkgs.vesktop.override (old: {
        vencord = old.vencord.overrideAttrs (
          prev:
          let
            customSounds = pkgs.fetchFromGitHub {
              owner = "ScattrdBlade";
              repo = "customSounds";
              rev = "main";
              hash = "sha256-05YlB5AmUJLCJPyXDamxEfDRFom4xtSNNuAohBC9vH8=";
            };
          in
          {
            postPatch = (prev.postPatch or "") + ''
              mkdir -p src/userplugins/customSounds
              cp ${customSounds}/*.ts* src/userplugins/customSounds&
            '';
          }
        );
      });
    };

    catppuccin.vesktop.enable = config.catppuccin.enable;

    systemd.user.services.mprisence = mkIf cfg.mprisence.enable {
      Unit = {
        Description = "Discord Rich Presence for MPRIS";
        After = [ "graphical-session.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Service = {
        Environment = "HOME=/run/user/%U/mprisence";
        RuntimeDirectory = "mprisence";
        ExecStart = "${pkgs.mprisence}/bin/mprisence";

        ExecStartPre = [
          (pkgs.writeShellScript "mprisence-init" ''
            mkdir -p "$HOME/.config/mprisence"
            cat > "$HOME/.config/mprisence/config.toml" <<'EOF'
            [player.mozilla_firefox]
            ignore = false
            EOF
          '')
        ];
      };

      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
  };
}
