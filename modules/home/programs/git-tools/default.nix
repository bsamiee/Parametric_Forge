# Title         : default.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/git-tools/default.nix
# ----------------------------------------------------------------------------
# Git tools owner: config modules plus the config-free package table
{
  lib,
  pkgs,
  ...
}: let
  manifest = import ../../../../overlays/manifest.nix;
  # Git-lane admissions from the package manifest: git-cliff (changelog),
  # mergiraf (structural merge driver; registration rides git.nix).
  gitRoster =
    map (row: pkgs.${row.attr})
    (lib.filter (row: row.install == "hm-roster" && row.roster == "git")
      (lib.attrValues manifest.admissions));
  # 1Password agent socket, HOME-relative; matches the IdentityAgent row in shell-tools/ssh.nix.
  opAgentSock = "Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock";
  # Receipt surface for the identity/signing/fsmonitor rail.
  # doctor: resolved identity, signing rows, op-agent key service, fsmonitor daemon health.
  # sign-proof: empty signed commit in a throwaway repo, verified locally.
  # verify [ref]: GitHub-side verification status for a pushed commit.
  forge-git-doctor = pkgs.writeShellApplication {
    name = "forge-git-doctor";
    runtimeInputs = [pkgs.git pkgs.gh pkgs.coreutils pkgs.gnugrep pkgs.openssh];
    text = ''
      mode="''${1:-doctor}"
      case "$mode" in
        doctor)
          printf '%-26s %s <%s>\n' "identity" "$(git config get user.name || echo UNSET)" "$(git config get user.email || echo UNSET)"
          for key in user.signingkey commit.gpgsign tag.gpgsign gpg.format gpg.ssh.program gpg.ssh.allowedsignersfile; do
            printf '%-26s %s\n' "$key" "$(git config get "$key" || echo UNSET)"
          done
          printf '%-26s %s\n' "gitleaks" "''${GITLEAKS_CONFIG:-UNSET}"
          # A configured signer that is not executable fails every commit at sign time.
          signer="$(git config get gpg.ssh.program || true)"
          if [ -z "$signer" ]; then
            printf '%-26s %s\n' "signer-binary" "UNSET (signing rows not deployed)"
          elif [ -x "$signer" ]; then
            printf '%-26s %s\n' "signer-binary" "executable"
          else
            printf '%-26s %s\n' "signer-binary" "MISSING at $signer (1Password.app absent or path stale)"
          fi
          # Signing goes live only when the op agent serves the configured key.
          sock="$HOME/${opAgentSock}"
          pubkey="$(git config get user.signingkey || true)"
          pubkey="''${pubkey#key::}"
          if [ -S "$sock" ] && [ -n "$pubkey" ] && SSH_AUTH_SOCK="$sock" ssh-add -L 2>/dev/null | grep -qF "$pubkey"; then
            printf '%-26s %s\n' "op-agent" "serves signing key"
          else
            printf '%-26s %s\n' "op-agent" "signing key NOT served (agent off or vault item missing)"
          fi
          if git rev-parse --git-dir >/dev/null 2>&1; then
            printf '%-26s %s\n' "fsmonitor" "$(git fsmonitor--daemon status 2>&1 || true)"
          else
            printf '%-26s %s\n' "fsmonitor" "outside a repository"
          fi
          ;;
        sign-proof)
          tmp="$(mktemp -d)"
          trap 'rm -rf "$tmp"' EXIT
          git -C "$tmp" init --quiet
          # No fsmonitor daemon for a repo the EXIT trap deletes.
          git -C "$tmp" config core.fsmonitor false
          git -C "$tmp" commit --allow-empty --quiet -m "forge signing proof"
          git -C "$tmp" log --show-signature -1
          ;;
        verify)
          sha="$(git rev-parse "''${2:-HEAD}")"
          repo="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
          gh api "repos/$repo/commits/$sha" --jq '.commit.verification | "verified=\(.verified) reason=\(.reason)"'
          ;;
        *)
          printf 'usage: forge-git-doctor [doctor|sign-proof|verify [ref]]\n' >&2
          exit 2
          ;;
      esac
    '';
  };
in {
  imports = [
    ./git.nix
    ./gh.nix
    ./lazygit.nix
    ./gitleaks.nix
  ];

  # Config-free git estate tools plus manifest git-roster rows.
  home.packages =
    [
      pkgs.git-quick-stats
      pkgs.difftastic
      forge-git-doctor
    ]
    ++ gitRoster;
}
