{
  host,
  pkgs,
  ...
}: {
  programs = {
    nh = {
      enable = true;
      package = pkgs.nh-current;
      flake = host.flakeRoot;
    };
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };

  home.packages = [
    pkgs.alejandra
    pkgs.cachix
    pkgs.dix
    pkgs.nixd
    pkgs.nurl
  ];
}
