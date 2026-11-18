_: {
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      pager = "delta";
      telemetry = "disabled";
      prompt = "disabled";
      spinner = "disabled";
    };
  };
}
