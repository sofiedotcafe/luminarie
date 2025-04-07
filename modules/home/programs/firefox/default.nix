{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.modules.home.programs.firefox;
  browser = "firefox.desktop";
in
{
  options.modules.home = {
    programs = {
      firefox = {
        enable = mkEnableOption "firefox";
        package = mkOption {
          type = types.package;
          default = pkgs.firefox-bin;
          description = ''
            The package of Firefox.
          '';
        };
        theme.package = mkOption {
          example = pkgs.firefox-gnome-theme;
          type = types.nullOr types.package;
          default = pkgs.firefox-gnome-theme;
          description = ''
            The user theme to apply to Firefox.
          '';
        };
      };
    };
  };
  config = mkIf cfg.enable {
    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/x-extension-htm" = [ browser ];
        "application/x-extension-html" = [ browser ];
        "application/x-extension-shtml" = [ browser ];
        "application/x-extension-xht" = [ browser ];
        "application/x-extension-xhtml" = [ browser ];
        "application/xhtml+xml" = [ browser ];
        "application/json" = [ browser ];
        "text/html" = [ browser ];
        "x-scheme-handler/about" = [ browser ];
        "x-scheme-handler/ftp" = [ browser ];
        "x-scheme-handler/http" = [ browser ];
        "x-scheme-handler/https" = [ browser ];
        "x-scheme-handler/unknown" = [ browser ];
      };
    };
    home.file = {
      ".mozilla/firefox/${config.home.username}/chrome/".source = mkIf (
        cfg.theme.package != null
      ) cfg.theme.package;
    };
    programs.firefox = {
      enable = true;
      inherit (cfg) package;
      policies = {
        # Documentation: https://mozilla.github.io/policy-templates/

        AppAutoUpdate = false;
        BackgroundAppUpdate = false;

        #DisableBuiltinPDFViewer = true;
        DisableFirefoxStudies = true;
        DisableFirefoxAccounts = true;
        DisableFirefoxScreenshots = true;
        DisableForgetButton = false;
        DisableMasterPasswordCreation = false;

        DisplayMenuBar = "default-off";

        DisableProfileImport = true;
        DisableProfileRefresh = true;
        DisableSetDesktopBackground = true;

        DisablePocket = true;
        DisableTelemetry = true;
        DisableFormHistory = true;
        DisablePasswordReveal = true;
        DontCheckDefaultBrowser = true;
        HardwareAcceleration = true;
        OfferToSaveLogins = true;

        EnableTrackingProtection = {
          Value = true;
          Locked = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        EncryptedMediaExtensions = {
          Enabled = true;
          Locked = true;
        };

        ExtensionUpdate = false;
        ExtensionSettings =
          with builtins;
          let
            extension = uuid: path: {
              name = uuid;
              value = {
                install_url = path;
                installation_mode = "force_installed";
              };
            };
          in
          listToAttrs [
            {
              name = "*";
              value = {
                installation_mode = "blocked";
                blocked_install_message = "Please do not install from here, only from Nix. ≧◡≦";
              };
            }
            (extension "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi")
            (extension "uBlock0@raymondhill.net" "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi")
            (extension "shinigamieyes@shinigamieyes" "https://addons.mozilla.org/firefox/downloads/latest/shinigami-eyes/latest.xpi")
          ];

        "3rdparty".Extensions = {
          # https://github.com/gorhill/uBlock/blob/master/platform/common/managed_storage.json
          "uBlock0@raymondhill.net".adminSettings = {
            userSettings = {
              uiTheme = "dark";
              uiAccentCustom = true;
              uiAccentCustom0 = "#b4befe";
              cloudStorageEnabled = false;
            };
            selectedFilterLists = [
              "adguard-generic"
              "adguard-annoyance"
              "adguard-cookies"
              "adguard-social"
              "adguard-spyware"
              "adguard-spyware-url"
              "adguard-popup-overlays"
              "adguard-other-annoyances"
              "adguard-widgets"
              "block-lan"
              "curben-phishing"
              "dpollock-0"
              "easylist"
              "easylist-chat"
              "easylist-newsletters"
              "easylist-notifications"
              "easylist-annoyances"
              "easyprivacy"
              "fanboy-cookiemonster"
              "fanboy-social"
              "fanboy-thirdparty_social"
              "FIN-0"
              "plowe-0"
              "ublock-abuse"
              "ublock-badware"
              "ublock-cookies-adguard"
              "ublock-cookies-easylist"
              "ublock-filters"
              "ublock-privacy"
              "ublock-quick-fixes"
              "ublock-unbreak"
              "ublock-annoyances"
              "urlhaus-1"
            ];
          };
        };

        FirefoxHome = {
          Search = true;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
        };

        FirefoxSuggest = {
          WebSuggestions = false;
          SponsoredSuggestions = false;
          ImproveSuggest = false;
          Locked = true;
        };

        NoDefaultBookmarks = true;
        PasswordManagerEnabled = true;

        # PDFjs = {
        #  Enabled = false;
        #  EnablePermissions = false;
        # };

        PictureInPicture = {
          Enabled = true;
          Locked = true;
        };

        PrimaryPassword = true;
        PromptForDownloadLocation = true;

        SanitizeOnShutdown = {
          Cache = true;
          Cookies = false;
          Downloads = true;
          FormData = true;
          History = false;
          Sessions = false;
          SiteSettings = false;
          OfflineApps = false;
          Locked = true;
        };

        SearchSuggestEnabled = false;
        ShowHomeButton = true;
        StartDownloadsInTempDirectory = false;
        UserMessaging = {
          ExtensionRecommendations = false;
          FeatureRecommendations = false;
          Locked = true;
          MoreFromMozilla = false;
          SkipOnboarding = true;
          UrlbarInterventions = false;
          WhatsNew = false;
        };
        UseSystemPrintDialog = true;
        Preferences = {
          "browser.urlbar.suggest.topsites" = false;
          "general.smoothScroll" = true;
        };
      };
      arkenfox.enable = true;
      profiles = {
        "${config.home.username}" = {
          id = 0;
          isDefault = true;
          name = "${config.home.username}";

          search = {
            force = true;
            default = "google";

            engines = {
              "NixOS Packages" = {
                definedAliases = [ "@np" ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://search.nixos.org/packages";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "NixOS Options" = {
                definedAliases = [ "@no" ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://search.nixos.org/options";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              "Home Manager Options" = {
                definedAliases = [ "@hm" ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                urls = [
                  {
                    template = "https://home-manager-options.extranix.com";
                    params = [
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
              };
              wikipedia.metaData.alias = "@wiki";
              amazondotcom-us.metaData.hidden = true;
              bing.metaData.hidden = true;
              ebay.metaData.hidden = true;
            };
          };

          settings = {
            # These are the settings for profile dependant (e.g. chrome themes) settings. ^-^
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "browser.uidensity" = 0;
            "browser.theme.dark-private-windows" = false;
            "browser.toolbars.bookmarks.visibility" = "never";
            "svg.context-properties.content.enabled" = true;
            "widget.gtk.rounded-bottom-corners.enabled" = true;
          };

          arkenfox = {
            enable = true;
            # Documentation:
            # nix build "github:dwarfmaster/arkenfox-nixos#arkenfox-v122_0-doc-static"

            # STARTUP
            "0100" = {
              "0105".enable = true;
            };

            # GEOLOCATION
            "0200".enable = true;

            # QUIETER FOX
            "0300".enable = true;

            # BLOCK IMPLICIT OUTBOUND [not explicitly asked for - e.g. clicked on]
            "0600".enable = true;

            # DNS / DoH / PROXY / SOCKS
            "0700".enable = true;

            # LOCATION BAR / SEARCH BAR / SUGGESTIONS / HISTORY / FORM
            "0800".enable = true;

            # PASSWORDS
            "0900".enable = true;

            # DISK AVOIDANCE
            "1000" = {
              enable = true;
              "1001".enable = false; # Don't disable disk cache
            };

            # HTTPS (SSL/TLS / OCSP / CERTS / HPKP)
            "1200".enable = true;

            # REFERERS
            "1600".enable = true;

            # CONTAINERS
            "1700".enable = true;

            # PLUGINS / MEDIA / WEBRTC
            "2000".enable = true;

            # DOM (DOCUMENT OBJECT MODEL)
            "2400".enable = true;

            # MISCELLANEOUS
            "2600".enable = true;

            # ETP (ENHANCED TRACKING PROTECTION)
            "2700".enable = true;

            # FPP (fingerprintingProtection)
            "4000".enable = true;

            # RFP (resistFingerprinting)
            #"4500" = {
            #  enable = true;
            #  "4504".enable = false; # Disable RFP letterboxing
            #  # "4520".enable = false; # Don't disable WebGL (Web Graphics Library). You probably don't always want this, but yea.... who uses this shit anyway, since WebGPU is becoming more mainstream anyways?
            #};

            # OPTIONAL OPSEC
            "5000" = {
              "5004".enable = true; # Disable permissions manager from writing to disk [FF41+] [RESTART]
              "5007".enable = true; # Exclude "Undo Closed Tabs" in Session Restore
              "5008".enable = true; # Disable resuming session from crash
              "5009".enable = true; # Disable "open with" in download dialog [FF50+]
              "5016".enable = true; # Discourage downloading to desktop
              "5018".enable = true; # Limit events that can cause a pop-up
            };

            # OPTIONAL HARDENING
            "5500"."5505".enable = true; # Disable Ion and baseline JIT to harden against JS exploits

            # DONT TOUTCH
            "6000".enable = true;

            # NON-PROJECT RELATED
            "9000".enable = true;
          };
        };
      };
    };
  };
}
