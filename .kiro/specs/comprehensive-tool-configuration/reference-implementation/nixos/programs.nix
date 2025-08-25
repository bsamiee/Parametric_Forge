# Title         : programs.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /reference-implementation/nixos/programs.nix
# ----------------------------------------------------------------------------
# NixOS-specific program configurations for Linux-only tools

{ config, lib, pkgs, ... }:

lib.mkIf pkgs.stdenv.isLinux {
  # --- Git Configuration (Linux-Specific) -----------------------------------
  programs.git = lib.mkIf config.programs.git.enable {
    extraConfig = {
      # Linux-specific credential helper
      credential.helper = "store";
      
      # SSH multiplexing for better performance
      core.sshCommand = "ssh -o ControlMaster=auto -o ControlPersist=60s";
      
      # Linux-specific diff and merge tools
      diff.tool = "vimdiff";
      merge.tool = "vimdiff";
      
      # Linux-specific pager configuration
      core.pager = lib.mkIf (lib.hasAttr "delta" pkgs) "delta --features=side-by-side";
      
      # Linux-specific editor
      core.editor = "nvim";
    };
  };

  # --- SSH Configuration (Linux-Specific) -----------------------------------
  programs.ssh = {
    enable = true;
    controlMaster = "auto";
    controlPersist = "60s";
    controlPath = "${config.xdg.runtimeDir}/ssh-%r@%h:%p";
    
    extraConfig = ''
      # Linux-specific SSH configuration
      
      # Use system SSH agent
      AddKeysToAgent yes
      IdentityAgent $SSH_AUTH_SOCK
      
      # Linux-specific security settings
      HashKnownHosts yes
      VerifyHostKeyDNS ask
      
      # Performance optimizations for Linux
      Compression yes
      ServerAliveInterval 60
      ServerAliveCountMax 3
      
      # Linux-specific paths
      UserKnownHostsFile ${config.xdg.dataHome}/ssh/known_hosts
      IdentityFile ${config.xdg.dataHome}/ssh/id_rsa
      IdentityFile ${config.xdg.dataHome}/ssh/id_ed25519
      IdentityFile ${config.xdg.dataHome}/ssh/id_ecdsa
    '';
  };

  # --- GPG Configuration (Linux-Specific) -----------------------------------
  programs.gpg = {
    enable = true;
    homedir = "${config.xdg.dataHome}/gnupg";
    
    settings = {
      # Linux-specific GPG settings
      use-agent = true;
      charset = "utf-8";
      fixed-list-mode = true;
      keyid-format = "0xlong";
      list-options = "show-uid-validity";
      verify-options = "show-uid-validity";
      with-fingerprint = true;
      
      # Linux-specific keyserver configuration
      keyserver = "hkps://keys.openpgp.org";
      keyserver-options = "auto-key-retrieve";
      
      # Linux-specific trust model
      trust-model = "pgp";
      
      # Linux-specific cipher preferences
      personal-cipher-preferences = "AES256 AES192 AES";
      personal-digest-preferences = "SHA512 SHA384 SHA256";
      personal-compress-preferences = "ZLIB BZIP2 ZIP Uncompressed";
      
      # Linux-specific certificate digest algorithm
      cert-digest-algo = "SHA512";
      
      # Disable weak algorithms
      weak-digest = "SHA1";
    };
  };

  # --- Shell Configuration (Linux-Specific) ---------------------------------
  programs.zsh = lib.mkIf config.programs.zsh.enable {
    initExtra = lib.mkAfter ''
      # Linux-specific shell configuration
      
      # Set up SSH agent if not already running
      if [[ -z "$SSH_AUTH_SOCK" ]]; then
        if systemctl --user is-active ssh-agent.service >/dev/null 2>&1; then
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
        else
          eval "$(ssh-agent -s)" >/dev/null 2>&1
          ssh-add ~/.ssh/id_* >/dev/null 2>&1
        fi
      fi
      
      # Linux-specific aliases
      alias open='xdg-open'
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
      
      # systemd user service management
      alias user-services='systemctl --user list-units --type=service'
      alias user-start='systemctl --user start'
      alias user-stop='systemctl --user stop'
      alias user-restart='systemctl --user restart'
      alias user-status='systemctl --user status'
      alias user-enable='systemctl --user enable'
      alias user-disable='systemctl --user disable'
      alias user-logs='journalctl --user -u'
      alias user-follow='journalctl --user -f -u'
      
      # Container management (Linux-specific)
      alias docker-clean='docker system prune -af'
      alias podman-clean='podman system prune -af'
      alias containers-ps='podman ps -a'
      alias containers-images='podman images'
      
      # Linux system information
      alias sysinfo='hostnamectl && echo && systemctl status'
      alias diskinfo='df -h && echo && lsblk'
      alias meminfo='free -h && echo && cat /proc/meminfo | head -10'
      alias cpuinfo='lscpu && echo && cat /proc/cpuinfo | grep "model name" | head -1'
      alias netinfo='ip addr show && echo && ss -tuln'
      
      # Package management (NixOS-specific)
      alias nix-search='nix search nixpkgs'
      alias nix-shell-p='nix-shell -p'
      alias nix-env-list='nix-env -q'
      alias nix-collect-garbage='nix-collect-garbage -d'
      alias nixos-rebuild-switch='sudo nixos-rebuild switch'
      alias nixos-rebuild-test='sudo nixos-rebuild test'
      alias home-manager-switch='home-manager switch'
      
      # Font management
      alias font-cache='fc-cache -fv'
      alias font-list='fc-list'
      alias font-match='fc-match'
      
      # Desktop integration
      alias update-desktop='update-desktop-database ~/.local/share/applications'
      alias update-mime='update-mime-database ~/.local/share/mime'
      alias update-icons='gtk-update-icon-cache -t ~/.local/share/icons/hicolor'
    '';
    
    # Linux-specific shell options
    history = {
      path = "${config.xdg.dataHome}/zsh/history";
      size = 50000;
      save = 50000;
      extended = true;
      ignoreDups = true;
      ignoreSpace = true;
      share = true;
    };
    
    # Linux-specific completion configuration
    completionInit = ''
      # Load system completions
      if [[ -d /run/current-system/sw/share/zsh/site-functions ]]; then
        fpath=(/run/current-system/sw/share/zsh/site-functions $fpath)
      fi
      
      # Load user completions
      if [[ -d ${config.xdg.dataHome}/zsh/completions ]]; then
        fpath=(${config.xdg.dataHome}/zsh/completions $fpath)
      fi
      
      autoload -U compinit
      compinit -d ${config.xdg.cacheHome}/zsh/zcompdump
    '';
  };

  # --- Bash Configuration (Linux-Specific) ----------------------------------
  programs.bash = lib.mkIf config.programs.bash.enable {
    initExtra = ''
      # Linux-specific bash configuration
      
      # Set up SSH agent if not already running
      if [[ -z "$SSH_AUTH_SOCK" ]]; then
        if systemctl --user is-active ssh-agent.service >/dev/null 2>&1; then
          export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
        else
          eval "$(ssh-agent -s)" >/dev/null 2>&1
          ssh-add ~/.ssh/id_* >/dev/null 2>&1
        fi
      fi
      
      # Linux-specific aliases (same as zsh for consistency)
      alias open='xdg-open'
      alias pbcopy='xclip -selection clipboard'
      alias pbpaste='xclip -selection clipboard -o'
      
      # systemd user service management
      alias user-services='systemctl --user list-units --type=service'
      alias user-start='systemctl --user start'
      alias user-stop='systemctl --user stop'
      alias user-restart='systemctl --user restart'
      alias user-status='systemctl --user status'
      alias user-enable='systemctl --user enable'
      alias user-disable='systemctl --user disable'
      
      # Container management
      alias docker-clean='docker system prune -af'
      alias podman-clean='podman system prune -af'
      
      # System information
      alias sysinfo='hostnamectl && echo && systemctl status'
      alias diskinfo='df -h && echo && lsblk'
      alias meminfo='free -h && echo && cat /proc/meminfo | head -10'
    '';
    
    # Linux-specific history configuration
    historyControl = [ "ignoredups" "ignorespace" ];
    historyFile = "${config.xdg.dataHome}/bash/history";
    historyFileSize = 50000;
    historySize = 50000;
  };

  # --- Direnv Configuration (Linux-Specific) --------------------------------
  programs.direnv = {
    enable = true;
    enableZshIntegration = config.programs.zsh.enable;
    enableBashIntegration = config.programs.bash.enable;
    nix-direnv.enable = true;
    
    config = {
      # Linux-specific direnv configuration
      global = {
        hide_env_diff = true;
        strict_env = true;
        warn_timeout = "30s";
      };
    };
    
    stdlib = ''
      # Linux-specific direnv functions
      
      # Function to set up systemd user service environment
      use_systemd_env() {
        if systemctl --user is-active "$1.service" >/dev/null 2>&1; then
          eval "$(systemctl --user show-environment)"
        fi
      }
      
      # Function to set up container environment
      use_container() {
        local runtime="$1"
        case "$runtime" in
          docker)
            export DOCKER_HOST="unix:///var/run/docker.sock"
            ;;
          podman)
            export CONTAINERS_CONF="$XDG_CONFIG_HOME/containers/containers.conf"
            ;;
        esac
      }
    '';
  };

  # --- Neovim Configuration (Linux-Specific) --------------------------------
  programs.neovim = lib.mkIf config.programs.neovim.enable {
    extraLuaConfig = ''
      -- Linux-specific Neovim configuration
      
      -- Use system clipboard (requires xclip or wl-clipboard)
      vim.opt.clipboard = "unnamedplus"
      
      -- Linux-specific terminal integration
      if vim.env.XDG_SESSION_TYPE == "wayland" then
        -- Wayland-specific settings
        vim.g.clipboard = {
          name = "wl-clipboard",
          copy = {
            ["+"] = "wl-copy",
            ["*"] = "wl-copy --primary",
          },
          paste = {
            ["+"] = "wl-paste --no-newline",
            ["*"] = "wl-paste --no-newline --primary",
          },
          cache_enabled = 0,
        }
      else
        -- X11-specific settings
        vim.g.clipboard = {
          name = "xclip",
          copy = {
            ["+"] = "xclip -selection clipboard",
            ["*"] = "xclip -selection primary",
          },
          paste = {
            ["+"] = "xclip -selection clipboard -o",
            ["*"] = "xclip -selection primary -o",
          },
          cache_enabled = 0,
        }
      end
      
      -- Linux-specific file operations
      vim.opt.backupdir = vim.fn.expand("${config.xdg.stateHome}/nvim/backup")
      vim.opt.directory = vim.fn.expand("${config.xdg.stateHome}/nvim/swap")
      vim.opt.undodir = vim.fn.expand("${config.xdg.stateHome}/nvim/undo")
      
      -- Create directories if they don't exist
      local function ensure_dir(path)
        if vim.fn.isdirectory(path) == 0 then
          vim.fn.mkdir(path, "p")
        end
      end
      
      ensure_dir(vim.fn.expand("${config.xdg.stateHome}/nvim/backup"))
      ensure_dir(vim.fn.expand("${config.xdg.stateHome}/nvim/swap"))
      ensure_dir(vim.fn.expand("${config.xdg.stateHome}/nvim/undo"))
      
      -- Linux-specific external tool integration
      if vim.fn.executable("xdg-open") == 1 then
        vim.keymap.set("n", "gx", function()
          local url = vim.fn.expand("<cWORD>")
          vim.fn.system("xdg-open " .. vim.fn.shellescape(url))
        end, { desc = "Open URL/file with system default" })
      end
      
      -- Linux notification integration (if notify-send is available)
      if vim.fn.executable("notify-send") == 1 then
        vim.api.nvim_create_user_command("Notify", function(opts)
          vim.fn.system("notify-send 'Neovim' " .. vim.fn.shellescape(opts.args))
        end, { nargs = 1, desc = "Send Linux notification" })
      end
      
      -- Load Linux-specific configuration if it exists
      local linux_config = vim.fn.stdpath("config") .. "/lua/config/linux.lua"
      if vim.fn.filereadable(linux_config) == 1 then
        dofile(linux_config)
      end
    '';
  };

  # --- Starship Configuration (Linux-Specific) ------------------------------
  programs.starship = lib.mkIf config.programs.starship.enable {
    settings = {
      # Linux-specific starship configuration
      format = lib.mkDefault "$all$character";
      
      # Add systemd status to prompt
      custom.systemd = {
        command = "systemctl --user is-system-running";
        when = "command -v systemctl";
        format = "[$output]($style) ";
        style = "bold green";
        disabled = false;
      };
      
      # Container status
      custom.containers = {
        command = "podman ps -q | wc -l";
        when = "command -v podman";
        format = "🐳[$output]($style) ";
        style = "bold blue";
        disabled = false;
      };
      
      # Linux-specific OS detection
      os = {
        disabled = false;
        symbols = {
          NixOS = "❄️ ";
          Ubuntu = "🎯 ";
          Debian = "🌀 ";
          Fedora = "🎩 ";
          Arch = "🏹 ";
        };
      };
    };
  };
}