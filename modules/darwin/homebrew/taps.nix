# Title         : taps.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/homebrew/taps.nix
# ----------------------------------------------------------------------------
# Homebrew tap repositories
_: {
  homebrew.taps = [
    {
      # brew autoupdate agent; schedule reconciled by forge-brew-autoupdate. Brew 6 gates untrusted-tap external commands
      # (HOMEBREW_REQUIRE_TAP_TRUST); trusted = true persists tap trust at activation so the agent can run.
      name = "domt4/autoupdate";
      trusted = true;
    }
  ];
}
