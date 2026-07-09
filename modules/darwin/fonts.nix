# Title         : fonts.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/darwin/fonts.nix
# ----------------------------------------------------------------------------
# Font inventory plus direct-file projection into the user font domain. macOS
# registers ~/Library/Fonts payloads deterministically; the nested
# "/Library/Fonts/Nix Fonts" package tree depends on lazy fontd rescans.
{
  config,
  lib,
  pkgs,
  ...
}: let
  # --- Programming/Terminal Fonts -------------------------------------------
  # Plain upstream families plus the one symbols fallback; the patched
  # nerd-font trio is retired — icon coverage rides Symbols Nerd Font Mono
  # through the owner fallback chain at two orders of magnitude less closure.
  programming = with pkgs; [
    geist-font
    iosevka-bin
    hack-font
    nerd-fonts.symbols-only
    ibm-plex
    (noto-fonts.override {variants = ["NotoSansMono"];})
  ];

  # --- UI/System Fonts -------------------------------------------------------
  interface = with pkgs; [
    inter
    dm-sans
    overpass
    source-sans
    source-serif
  ];

  # --- Perso-Arabic Fonts ----------------------------------------------------
  persoArabic = with pkgs; [
    (noto-fonts.override {variants = ["NotoSansArabic" "NotoNaskhArabic"];})
    scheherazade-new
  ];

  fontPackages = programming ++ interface ++ persoArabic;
  userFontDir = "${config.users.users.${config.system.primaryUser}.home}/Library/Fonts";

  # Flat basename view of every font payload; the file set derives from package outputs.
  fontPayloads = pkgs.runCommand "forge-font-payloads" {preferLocalBuild = true;} ''
    mkdir -p $out
    while IFS= read -rd "" f; do
      ln -s "$f" "$out/''${f##*/}"
    done < <(
      find -L ${lib.escapeShellArgs fontPackages} -type f \
        -regex '.*\.\(ttf\|ttc\|otf\|dfont\)' -print0
    )
  '';

  # Generation-marked copy: prune stale managed files via manifest, never touch unmanaged fonts.
  projectFonts = pkgs.writeShellApplication {
    name = "forge-project-fonts";
    runtimeInputs = [pkgs.coreutils];
    text = ''
      src=${fontPayloads}
      dst=${lib.escapeShellArg userFontDir}
      marker="$dst/.forge-fonts-generation"
      manifest="$dst/.forge-fonts-manifest"
      if [[ -f $marker && "$(<"$marker")" == "$src" ]]; then exit 0; fi
      mkdir -p "$dst"
      pruned=0
      if [[ -f $manifest ]]; then
        while IFS= read -r name; do
          [[ -e "$src/$name" ]] || {
            rm -f "$dst/$name"
            ((++pruned))
          }
        done <"$manifest"
      fi
      cp -Lf "$src"/* "$dst/"
      (cd "$src" && printf '%s\n' *) >"$manifest"
      printf '%s' "$src" >"$marker"
      # Activation invokes this via sudo -u; anchor the log beside the payload,
      # never through an ambient HOME.
      logdir="''${dst%/Fonts}/Logs"
      ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
      mkdir -p "$logdir"
      printf 'ts=%s\towner=forge-project-fonts\tprojected=%s\tpruned=%s\tgeneration=%s\n' \
        "$ts" "$(wc -l <"$manifest" | tr -d ' ')" "$pruned" "''${src##*/}" \
        >>"$logdir/forge-fonts.receipts.log"
    '';
  };
in {
  fonts.packages = fontPackages;

  # Activation runs as root; the projection writes user-owned files in the user domain.
  system.activationScripts.postActivation.text = ''
    printf >&2 'projecting fonts into %s...\n' ${lib.escapeShellArg userFontDir}
    sudo -u ${lib.escapeShellArg config.system.primaryUser} ${projectFonts}/bin/forge-project-fonts
  '';
}
