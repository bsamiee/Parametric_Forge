{pkgs, ...}: {
  programs.gh = {
    enable = true;
    package = pkgs.gh-current;
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      pager = "delta";
      prompt = "disabled";
      spinner = "disabled";
    };
  };
}
