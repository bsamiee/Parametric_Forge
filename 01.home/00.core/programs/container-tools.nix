# Title         : container-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/container-tools.nix
# ----------------------------------------------------------------------------
# Container ecosystem tools: Docker UI and orchestration tools.

_:

{
  programs = {
    # --- Lazydocker Configuration --------------------------------------------
    lazydocker = {
      enable = true;
      settings = {
        # --- User Interface -------------------------------------------------
        gui = {
          theme = {
            # Dracula-inspired theme (limited to terminal colors)
            activeBorderColor = [ "green" "bold" ]; # Active borders
            inactiveBorderColor = [ "default" ]; # Inactive borders
            selectedLineBgColor = [ "magenta" ]; # Selected line - closest to Dracula purple
            optionsTextColor = [ "cyan" ]; # Options text
          };
          showAllContainers = false;
          scrollHeight = 2;
          scrollPastBottom = false;
          sidePanelWidth = 0.3333;
          showBottomLine = true;
          expandFocusedSidePanel = false;
          language = "auto";
          border = "rounded";
          containerStatusHealthStyle = "long";
          returnImmediately = false;
          wrapMainPanel = true;
        };
        # --- Docker Integration ---------------------------------------------
        commandTemplates = {
          dockerCompose = "docker compose";
          restartService = "{{ .DockerCompose }} restart {{ .Service.Name }}";
          up = "{{ .DockerCompose }} up -d";
          down = "{{ .DockerCompose }} down";
          downWithVolumes = "{{ .DockerCompose }} down --volumes";
          upService = "{{ .DockerCompose }} up -d {{ .Service.Name }}";
          startService = "{{ .DockerCompose }} start {{ .Service.Name }}";
          stopService = "{{ .DockerCompose }} stop {{ .Service.Name }}";
          rebuildService = "{{ .DockerCompose }} up -d --build {{ .Service.Name }}";
          recreateService = "{{ .DockerCompose }} up -d --force-recreate {{ .Service.Name }}";
          serviceLogs = "{{ .DockerCompose }} logs --since=60m --follow {{ .Service.Name }}";
          viewServiceLogs = "{{ .DockerCompose }} logs --follow {{ .Service.Name }}";
          allLogs = "{{ .DockerCompose }} logs --tail=300 --follow";
          viewAllLogs = "{{ .DockerCompose }} logs";
          dockerComposeConfig = "{{ .DockerCompose }} config";
          checkDockerComposeConfig = "{{ .DockerCompose }} config --quiet";
          serviceTop = "{{ .DockerCompose }} top {{ .Service.Name }}";
        };
        # --- Logs Configuration ---------------------------------------------
        logs = {
          timestamps = false;
          since = "60m";
          tail = "200";
        };
        # --- Stats Configuration --------------------------------------------
        stats = {
          graphs = [
            {
              caption = "CPU (%)";
              statPath = "DerivedStats.CPUPercentage";
              color = "cyan"; # CPU usage
            }
            {
              caption = "Memory (%)";
              statPath = "DerivedStats.MemoryPercentage";
              color = "green"; # Memory usage
            }
          ];
          maxDuration = "3m";  # Must be a duration string, not an integer
        };
        # --- Bulk Commands --------------------------------------------------
        bulkCommands = {
          services = [
            {
              name = "up";
              command = "{{ .DockerCompose }} up -d";
            }
            {
              name = "up (attached)";
              command = "{{ .DockerCompose }} up";
              attach = true;
            }
            {
              name = "stop";
              command = "{{ .DockerCompose }} stop";
            }
            {
              name = "pull";
              command = "{{ .DockerCompose }} pull";
              attach = true;
            }
            {
              name = "build";
              command = "{{ .DockerCompose }} build --parallel --force-rm";
              attach = true;
            }
            {
              name = "down";
              command = "{{ .DockerCompose }} down";
            }
            {
              name = "down with volumes";
              command = "{{ .DockerCompose }} down --volumes";
            }
          ];
          containers = [ ];
          images = [ ];
          volumes = [ ];
        };
        # --- OS Integration -------------------------------------------------
        oS = {
          openCommand = "open {{filename}}";
          openLinkCommand = "open {{link}}";
        };
        # --- Confirmation Settings ------------------------------------------
        confirmOnQuit = false;
        # --- Custom Commands ------------------------------------------------
        customCommands = {
          containers = [
            {
              name = "bash";
              attach = true;
              command = "docker exec -it {{ .Container.ID }} /bin/bash";
              serviceNames = [ ];
            }
            {
              name = "sh";
              attach = true;
              command = "docker exec -it {{ .Container.ID }} /bin/sh";
              serviceNames = [ ];
            }
          ];
          services = [ ];
          images = [ ];
          volumes = [ ];
          networks = [ ];
        };
        # --- Image Name Replacements ----------------------------------------
        replacements = {
          imageNamePrefixes = { };
        };
      };
    };
  };
}