{
  macbook = let
    home = "/Users/bardiasamiee";
  in {
    name = "macbook";
    label = "Bardia's MacBook Pro";
    system = "aarch64-darwin";
    stateVersion = {
      system = 7;
      home = "26.11";
    };
    user = {
      name = "bardiasamiee";
      inherit home;
    };
    flakeRoot = "${home}/Developer/Parametric_Forge";
    ssh.publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJ13xqqm/BVTzJNN/V0Cukvk4xAentt3qqE525URRqwS Bardia SSH Key";
    tailnet = {
      domain = "tailec0014.ts.net";
      range = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
      servers = ["derby" "lucky"];
    };
  };
}
