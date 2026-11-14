{
  inputs,
  self,
  ...
}: {
  perSystem = {system, ...}: let
    pkgs = import inputs.nixpkgs {
      inherit system;
      overlays = [self.overlays.default];
      config.allowUnfree = true;
    };
  in {
    _module.args.pkgs = pkgs;
    legacyPackages = pkgs;
  };
}
