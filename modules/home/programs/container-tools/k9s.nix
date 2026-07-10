# Title         : k9s.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/k9s.nix
# ----------------------------------------------------------------------------
# Terminal UI for Kubernetes cluster management; package row lives in the owner
# table. The forge skin is projected from the estate palette owner.
{
  config,
  pkgs,
  ...
}: let
  inherit (config.forge.theme) palette roles;
  yamlFormat = pkgs.formats.yaml {};

  forgeSkin.k9s = {
    body = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      logoColor = roles.accent.secondary.hex;
      logoColorMsg = roles.accent.primary.hex;
      logoColorInfo = roles.state.success.hex;
      logoColorWarn = roles.state.warning.hex;
      logoColorError = roles.state.danger.hex;
    };
    prompt = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      suggestColor = roles.text.muted.hex;
      border = {
        command = roles.accent.primary.hex;
        default = roles.surface.selected.hex;
      };
    };
    info = {
      fgColor = roles.text.muted.hex;
      sectionColor = roles.text.primary.hex;
      cpuColor = palette.cyan.hex;
      memColor = palette.purple.hex;
      k9sRevColor = roles.accent.secondary.hex;
    };
    dialog = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.raised.hex;
      buttonFgColor = roles.text.inverse.hex;
      buttonBgColor = palette.comment.hex;
      buttonFocusFgColor = roles.text.inverse.hex;
      buttonFocusBgColor = roles.accent.primary.hex;
      labelFgColor = roles.state.warning.hex;
      fieldFgColor = roles.text.primary.hex;
    };
    frame = {
      border = {
        fgColor = roles.surface.selected.hex;
        focusColor = roles.accent.primary.hex;
      };
      menu = {
        fgColor = roles.text.primary.hex;
        keyColor = roles.accent.primary.hex;
        numKeyColor = roles.accent.secondary.hex;
      };
      crumbs = {
        fgColor = roles.text.inverse.hex;
        bgColor = palette.comment.hex;
        activeColor = roles.accent.primary.hex;
      };
      status = {
        newColor = palette.cyan.hex;
        modifyColor = palette.purple.hex;
        addColor = palette.green.hex;
        pendingColor = roles.text.muted.hex;
        errorColor = palette.red.hex;
        highlightColor = palette.orange.hex;
        killColor = palette.comment.hex;
        completedColor = palette.comment.hex;
      };
      title = {
        fgColor = roles.text.primary.hex;
        bgColor = roles.surface.base.hex;
        highlightColor = palette.orange.hex;
        counterColor = palette.cyan.hex;
        filterColor = palette.magenta.hex;
      };
    };
    views = {
      charts = {
        bgColor = roles.surface.base.hex;
        dialBgColor = roles.surface.base.hex;
        chartBgColor = roles.surface.base.hex;
        defaultDialColors = [palette.green.hex palette.red.hex];
        defaultChartColors = [palette.green.hex palette.red.hex];
      };
      table = {
        fgColor = roles.text.primary.hex;
        bgColor = roles.surface.base.hex;
        cursorFgColor = roles.text.primary.hex;
        cursorBgColor = roles.surface.selected.hex;
        markColor = palette.pink.hex;
        header = {
          fgColor = roles.accent.primary.hex;
          bgColor = roles.surface.base.hex;
          sorterColor = palette.orange.hex;
          selectedSortColumnColor = palette.yellow.hex;
        };
      };
      xray = {
        fgColor = roles.text.primary.hex;
        bgColor = roles.surface.base.hex;
        cursorColor = roles.surface.selected.hex;
        cursorTextColor = roles.text.primary.hex;
        graphicColor = roles.accent.secondary.hex;
      };
      yaml = {
        keyColor = palette.green.hex;
        colonColor = palette.magenta.hex;
        valueColor = palette.yellow.hex;
      };
      logs = {
        fgColor = roles.text.primary.hex;
        bgColor = roles.surface.base.hex;
        indicator = {
          fgColor = roles.text.inverse.hex;
          bgColor = roles.accent.structural.hex;
          toggleOnColor = roles.state.success.hex;
          toggleOffColor = roles.text.muted.hex;
        };
      };
    };
  };
  # Mouse/chrome toggles live under k9s.ui only; top-level twins are ignored.
  forgeConfig.k9s = {
    liveViewAutoRefresh = true;
    refreshRate = 2;
    maxConnRetry = 5;
    readOnly = true;
    noExitOnCtrlC = false;
    ui = {
      enableMouse = true;
      headless = false;
      logoless = false;
      crumbsless = false;
      noIcons = false;
      skin = "forge";
    };
    logger = {
      tail = 200;
      buffer = 5000;
      sinceSeconds = 300;
      textWrap = false;
      showTime = true;
    };
  };

  # CRD front doors; a new hotkey/alias/plugin is one attrset row.
  hotKey = shortCut: description: command: {inherit shortCut description command;};
  forgeHotkeys.hotKeys = {
    shift-a = hotKey "Shift-A" "ArgoCD Applications" "applications.argoproj.io";
    shift-k = hotKey "Shift-K" "Kyverno PolicyReports" "policyreports.wgpolicyk8s.io";
    shift-d = hotKey "Shift-D" "CloudNativePG Clusters" "clusters.postgresql.cnpg.io";
    shift-i = hotKey "Shift-I" "Traefik IngressRoutes" "ingressroutes.traefik.io";
    shift-s = hotKey "Shift-S" "SealedSecrets" "sealedsecrets.bitnami.com";
  };

  forgeAliases.aliases = {
    # ArgoCD
    app = "argoproj.io/v1alpha1/applications";
    appproj = "argoproj.io/v1alpha1/appprojects";
    # Kyverno
    cpol = "kyverno.io/v1/clusterpolicies";
    pol = "kyverno.io/v1/policies";
    pr = "wgpolicyk8s.io/v1alpha2/policyreports";
    cpr = "wgpolicyk8s.io/v1alpha2/clusterpolicyreports";
    # CloudNativePG
    pg = "postgresql.cnpg.io/v1/clusters";
    backup = "postgresql.cnpg.io/v1/backups";
    # Traefik
    ir = "traefik.io/v1alpha1/ingressroutes";
    mw = "traefik.io/v1alpha1/middlewares";
    # SealedSecrets
    ss = "bitnami.com/v1alpha1/sealedsecrets";
  };

  forgePlugins.plugins = {
    logs-previous = {
      shortCut = "Shift-L";
      description = "Previous container logs";
      scopes = ["pods"];
      command = "kubectl";
      background = false;
      args = ["logs" "$NAME" "-n" "$NAMESPACE" "--previous" "--tail=100"];
    };
  };
in {
  xdg.configFile = {
    "k9s/skins/forge.yaml".source = yamlFormat.generate "k9s-forge-skin" forgeSkin;
    "k9s/config.yaml".source = yamlFormat.generate "k9s-config" forgeConfig;
    "k9s/hotkeys.yaml".source = yamlFormat.generate "k9s-hotkeys" forgeHotkeys;
    "k9s/aliases.yaml".source = yamlFormat.generate "k9s-aliases" forgeAliases;
    "k9s/plugins.yaml".source = yamlFormat.generate "k9s-plugins" forgePlugins;
  };
}
