{
  host,
  pkgs,
  ...
}: {
  programs = {
    nh = {
      enable = true;
      package = pkgs.nh;
      flake = host.flakeRoot;
    };
    nix-index.enable = true;
    nix-index-database.comma.enable = true;
  };

  home.packages = [
    pkgs.alejandra
    pkgs.dix
    pkgs.nixd
  ];
}
