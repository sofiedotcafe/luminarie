{
  lib,
  config,
  pkgs,
  ...
}:
{
  disabledModules = [ "profiles/base.nix" ];

  nixpkgs.overlays = [
    (_: prev: {
      makeModulesClosure = x: prev.makeModulesClosure (x // { allowMissing = true; });
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (
          _: prev:
          builtins.listToAttrs (
            map
              (name: {
                inherit name;
                value = prev.${name}.overridePythonAttrs (_: {
                  doCheck = false;
                });
              })
              [
                "dbus-next"
                "python-can"
                "curl-cffi"
              ]
          )
        )
      ];
    })
  ];

  system.nixos.tags = [
    "raspberry-pi-${config.boot.loader.raspberry-pi.variant}"
    config.boot.loader.raspberry-pi.bootloader
    config.boot.kernelPackages.kernel.version
  ];

  boot.blacklistedKernelModules = [ "brcmfmac" ];
  boot.kernelModules = [
    "i2c-dev"
    "i2c-bcm2835"
  ];

  hardware.raspberry-pi.config.all = {
    dt-overlays = {
      vc4-kms-dsi-waveshare-panel = {
        enable = true;
        params."5_0_inch".enable = true;
      };
    };
    base-dt-params = {
      i2c_arm = {
        enable = true;
        value = "on";
      };
      i2c_vc = {
        enable = true;
        value = "on";
      };
    };
  };

  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    i2c-tools
    libinput
    libdrm
    git
  ];

  networking.useDHCP = lib.mkDefault true;
  networking.networkmanager.enable = true;
}
