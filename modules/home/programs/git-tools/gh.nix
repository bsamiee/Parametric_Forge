{pkgs, ...}: {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    extensions = [pkgs.gh-actions-lock];
    settings = {
      git_protocol = "ssh";
      pager = "delta";
      telemetry = "disabled";
      prompt = "disabled";
      spinner = "disabled";
    };
  };
}
