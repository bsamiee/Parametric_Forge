# Title         : k9s.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : modules/home/programs/container-tools/k9s.nix
# ----------------------------------------------------------------------------
# Terminal UI for Kubernetes cluster management
{pkgs, ...}: {
  home.packages = [pkgs.k9s];

  # --- CONFIG -----------------------------------------------------------------
  xdg.configFile."k9s/config.yaml".text = ''
    k9s:
      liveViewAutoRefresh: true
      refreshRate: 2
      maxConnRetry: 5
      enableMouse: true
      headless: false
      logoless: false
      crumbsless: false
      readOnly: false
      noExitOnCtrlC: false
      ui:
        enableSkips: false
        headless: false
        logoless: false
        crumbsless: false
        noIcons: false
        skin: dracula
      logger:
        tail: 200
        buffer: 5000
        sinceSeconds: 300
        textWrap: false
        showTime: true
  '';

  # --- HOTKEYS ----------------------------------------------------------------
  xdg.configFile."k9s/hotkeys.yaml".text = ''
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
  xdg.configFile."k9s/aliases.yaml".text = ''
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
  xdg.configFile."k9s/plugins.yaml".text = ''
    plugins:
      # Decode base64 secret
      decode-secret:
        shortCut: Ctrl-X
        description: Decode secret
        scopes:
          - secrets
        command: bash
        background: false
        args:
          - -c
          - "kubectl get secret $NAME -n $NAMESPACE -o jsonpath='{.data}' | jq -r 'to_entries[] | \"\\(.key): \\(.value | @base64d)\"'"
      # Restart deployment
      restart-deploy:
        shortCut: Ctrl-R
        description: Restart deployment
        scopes:
          - deployments
        command: kubectl
        background: false
        confirm: true
        args:
          - rollout
          - restart
          - deployment
          - $NAME
          - -n
          - $NAMESPACE
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
}
