# SSH via 1Password agent (Parametric Forge)

programs.ssh = {
  enable = true;
  extraConfig = ''
    Host *
      IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
  '';
  matchBlocks.github.com = {
    user = "git";
    identitiesOnly = true;
    addKeysToAgent = "yes";
  };
};
