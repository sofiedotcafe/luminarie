{
  lib,
  modulesPath,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/sd-card/sd-image-aarch64.nix")
    (modulesPath + "/profiles/minimal.nix")
  ];

  disabledModules = [ "profiles/base.nix" ];

  sdImage.compressImage = false;

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

  boot.blacklistedKernelModules = [ "brcmfmac" ];

  networking.useDHCP = lib.mkDefault true;
}
