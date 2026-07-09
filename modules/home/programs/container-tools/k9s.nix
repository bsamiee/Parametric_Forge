# Title         : k9s.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /modules/home/programs/container-tools/k9s.nix
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
    };
    prompt = {
      fgColor = roles.text.primary.hex;
      bgColor = roles.surface.base.hex;
      suggestColor = roles.text.muted.hex;
    };
    info = {
      fgColor = roles.text.muted.hex;
      sectionColor = roles.text.primary.hex;
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
        };
      };
      xray = {
        fgColor = roles.text.primary.hex;
        bgColor = roles.surface.base.hex;
        cursorColor = roles.surface.selected.hex;
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
        };
      };
    };
  };
in {
  xdg.configFile = {
    # --- SKIN -------------------------------------------------------------------
    "k9s/skins/forge.yaml".source = yamlFormat.generate "k9s-forge-skin" forgeSkin;

    # --- CONFIG -----------------------------------------------------------------
    "k9s/config.yaml".text = ''
      k9s:
        liveViewAutoRefresh: true
        refreshRate: 2
        maxConnRetry: 5
        enableMouse: true
        headless: false
        logoless: false
        crumbsless: false
        readOnly: true
        noExitOnCtrlC: false
        ui:
          enableSkips: false
          headless: false
          logoless: false
          crumbsless: false
          noIcons: false
          skin: forge
        logger:
          tail: 200
          buffer: 5000
          sinceSeconds: 300
          textWrap: false
          showTime: true
    '';

    # --- HOTKEYS ----------------------------------------------------------------
    "k9s/hotkeys.yaml".text = ''
      hotKeys:
        # ArgoCD Applications
        shift-a:
          shortCut: Shift-A
          description: ArgoCD Applications
          command: applications.argoproj.io
        # Kyverno PolicyReports
        shift-k:
          shortCut: Shift-K
          description: Kyverno PolicyReports
          command: policyreports.wgpolicyk8s.io
        # CloudNativePG Clusters
        shift-d:
          shortCut: Shift-D
          description: CloudNativePG Clusters
          command: clusters.postgresql.cnpg.io
        # IngressRoutes (Traefik)
        shift-i:
          shortCut: Shift-I
          description: Traefik IngressRoutes
          command: ingressroutes.traefik.io
        # SealedSecrets
        shift-s:
          shortCut: Shift-S
          description: SealedSecrets
          command: sealedsecrets.bitnami.com
    '';

    # --- ALIASES ----------------------------------------------------------------
    "k9s/aliases.yaml".text = ''
      aliases:
        # ArgoCD CRDs
        app: argoproj.io/v1alpha1/applications
        appproj: argoproj.io/v1alpha1/appprojects
        # Kyverno CRDs
        cpol: kyverno.io/v1/clusterpolicies
        pol: kyverno.io/v1/policies
        pr: wgpolicyk8s.io/v1alpha2/policyreports
        cpr: wgpolicyk8s.io/v1alpha2/clusterpolicyreports
        # CloudNativePG CRDs
        pg: postgresql.cnpg.io/v1/clusters
        backup: postgresql.cnpg.io/v1/backups
        # Traefik CRDs
        ir: traefik.io/v1alpha1/ingressroutes
        mw: traefik.io/v1alpha1/middlewares
        # SealedSecrets
        ss: bitnami.com/v1alpha1/sealedsecrets
    '';

    # --- PLUGINS ----------------------------------------------------------------
    "k9s/plugins.yaml".text = ''
      plugins:
        # View previous logs
        logs-previous:
          shortCut: Shift-L
          description: Previous container logs
          scopes:
            - pods
          command: kubectl
          background: false
          args:
            - logs
            - $NAME
            - -n
            - $NAMESPACE
            - --previous
            - --tail=100
    '';
  };
}
