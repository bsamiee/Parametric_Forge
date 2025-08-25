# Title         : container-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/container-tools.nix
# ----------------------------------------------------------------------------
# Container ecosystem tools: docker-client (Docker CLI) and colima (container runtime).
# These tools provide comprehensive container management capabilities with
# modern interfaces and cross-platform compatibility for development workflows.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- Docker Client Configuration ----------------------------------
    # Docker CLI client for container management and orchestration
    # Provides comprehensive container lifecycle management capabilities
    # Note: Docker daemon managed by system configuration, this configures CLI only
    # TODO: No home-manager module available - requires config files
    
    # docker = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Client Configuration ----------------------------
    #     # Docker CLI behavior and defaults
    #     client = {
    #       # Default registry for image operations
    #       default_registry = "docker.io";
    #       
    #       # Automatically pull missing images
    #       auto_pull = true;
    #       
    #       # Default output format for commands
    #       format = "table";  # table, json, yaml
    #       
    #       # Enable experimental features
    #       experimental = false;
    #       
    #       # CLI plugins directory
    #       plugins_dir = "${config.xdg.configHome}/docker/cli-plugins";
    #     };
    #     
    #     # --- Build Configuration -----------------------------
    #     # Docker build settings and optimizations
    #     build = {
    #       # Default build context
    #       context = ".";
    #       
    #       # Build cache configuration
    #       cache = {
    #         enabled = true;
    #         max_size = "10GB";
    #         gc_policy = "auto";
    #       };
    #       
    #       # BuildKit configuration
    #       buildkit = {
    #         enabled = true;
    #         features = [
    #           "cache_mount"
    #           "bind_mount"
    #           "tmpfs_mount"
    #           "secrets"
    #           "ssh"
    #         ];
    #       };
    #       
    #       # Multi-platform build support
    #       platforms = [
    #         "linux/amd64"
    #         "linux/arm64"
    #       ];
    #     };
    #     
    #     # --- Registry Configuration --------------------------
    #     # Container registry settings
    #     registries = {
    #       # Registry mirrors for faster pulls
    #       mirrors = [
    #         "https://mirror.gcr.io"
    #       ];
    #       
    #       # Insecure registries (for development)
    #       insecure = [
    #         "localhost:5000"
    #         "registry.local:5000"
    #       ];
    #       
    #       # Registry authentication (stored securely)
    #       auth_config_path = "${config.xdg.configHome}/docker/config.json";
    #     };
    #     
    #     # --- Logging Configuration ---------------------------
    #     # Container logging settings
    #     logging = {
    #       # Default log driver
    #       driver = "json-file";
    #       
    #       # Log rotation settings
    #       options = {
    #         "max-size" = "10m";
    #         "max-file" = "3";
    #       };
    #     };
    #   };
    #   
    #   # --- Compose Configuration ---------------------------
    #   # Docker Compose settings and profiles
    #   compose = {
    #     # Default compose file names
    #     files = [
    #       "docker-compose.yml"
    #       "docker-compose.yaml"
    #       "compose.yml"
    #       "compose.yaml"
    #     ];
    #     
    #     # Environment file patterns
    #     env_files = [
    #       ".env"
    #       ".env.local"
    #       ".env.development"
    #     ];
    #     
    #     # Default profiles for different environments
    #     profiles = {
    #       development = [
    #         "app"
    #         "database"
    #         "cache"
    #       ];
    #       
    #       production = [
    #         "app"
    #         "database"
    #         "monitoring"
    #       ];
    #       
    #       testing = [
    #         "app"
    #         "test-database"
    #       ];
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     # Container management
    #     "dps" = "docker ps";
    #     "dpsa" = "docker ps -a";
    #     "di" = "docker images";
    #     "drmi" = "docker rmi";
    #     "drm" = "docker rm";
    #     
    #     # Container operations
    #     "drun" = "docker run --rm -it";
    #     "dexec" = "docker exec -it";
    #     "dlogs" = "docker logs -f";
    #     "dstop" = "docker stop";
    #     "dstart" = "docker start";
    #     
    #     # Docker Compose shortcuts
    #     "dc" = "docker compose";
    #     "dcup" = "docker compose up -d";
    #     "dcdown" = "docker compose down";
    #     "dclogs" = "docker compose logs -f";
    #     "dcbuild" = "docker compose build";
    #     "dcpull" = "docker compose pull";
    #     
    #     # Cleanup operations
    #     "dcleanup" = "docker system prune -f";
    #     "dcleanup-all" = "docker system prune -a -f";
    #     "dcleanup-volumes" = "docker volume prune -f";
    #   };
    # };

    # --- Colima Container Runtime ----------------------------------
    # Lightweight container runtime for macOS and Linux
    # Provides Docker-compatible API with minimal resource usage
    # TODO: No home-manager module available - requires config file
    
    # colima = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Runtime Configuration ---------------------------
    #     # Basic runtime settings
    #     runtime = "docker";      # docker, containerd
    #     arch = "aarch64";        # aarch64, x86_64
    #     cpu = 4;                 # Number of CPUs
    #     memory = 8;              # Memory in GB
    #     disk = 100;              # Disk size in GB
    #     
    #     # --- VM Configuration --------------------------------
    #     # Virtual machine settings (for macOS)
    #     vm = {
    #       # VM type
    #       type = "qemu";         # qemu, vz (macOS Virtualization.framework)
    #       
    #       # Network configuration
    #       network = {
    #         address = true;      # Assign IP address to VM
    #         dns = [
    #           "1.1.1.1"
    #           "8.8.8.8"
    #         ];
    #         dns_hosts = {};      # Custom DNS host mappings
    #       };
    #       
    #       # Mount configuration
    #       mounts = [
    #         {
    #           location = "~";
    #           writable = true;
    #           9p = {
    #             security_model = "none";
    #             protocol_version = "9p2000.L";
    #             msize = 128000;
    #             cache = "mmap";
    #           };
    #         }
    #         {
    #           location = "/tmp/colima";
    #           writable = true;
    #         }
    #       ];
    #       
    #       # Port forwarding
    #       forward_agent = false;
    #       
    #       # Environment variables
    #       env = {
    #         DOCKER_HOST = "unix:///var/run/docker.sock";
    #       };
    #     };
    #     
    #     # --- Docker Configuration ----------------------------
    #     # Docker daemon settings within Colima
    #     docker = {
    #       # Docker daemon features
    #       features = {
    #         buildkit = true;
    #         containerd_snapshotter = false;
    #       };
    #       
    #       # Daemon configuration
    #       daemon = {
    #         # Registry mirrors
    #         registry_mirrors = [
    #           "https://mirror.gcr.io"
    #         ];
    #         
    #         # Insecure registries
    #         insecure_registries = [
    #           "localhost:5000"
    #         ];
    #         
    #         # Storage driver
    #         storage_driver = "overlay2";
    #         
    #         # Logging configuration
    #         log_driver = "json-file";
    #         log_opts = {
    #           "max-size" = "10m";
    #           "max-file" = "3";
    #         };
    #         
    #         # Resource limits
    #         default_ulimits = {
    #           nofile = {
    #             hard = 65536;
    #             soft = 65536;
    #           };
    #         };
    #       };
    #     };
    #     
    #     # --- Kubernetes Configuration -----------------------
    #     # Kubernetes integration (optional)
    #     kubernetes = {
    #       enabled = false;
    #       version = "v1.28.2";
    #       ingress = false;
    #       
    #       # Kubernetes runtime
    #       runtime = "containerd";  # containerd, docker
    #       
    #       # Network plugin
    #       network = {
    #         plugin = "flannel";    # flannel, calico
    #         dns_domain = "cluster.local";
    #       };
    #     };
    #   };
    #   
    #   # --- Profiles ----------------------------------------
    #   # Predefined configurations for different use cases
    #   profiles = {
    #     # Development profile
    #     development = {
    #       cpu = 2;
    #       memory = 4;
    #       disk = 50;
    #       runtime = "docker";
    #       kubernetes = { enabled = false; };
    #     };
    #     
    #     # Production-like profile
    #     production = {
    #       cpu = 6;
    #       memory = 12;
    #       disk = 200;
    #       runtime = "containerd";
    #       kubernetes = { 
    #         enabled = true;
    #         version = "v1.28.2";
    #       };
    #     };
    #     
    #     # Minimal profile for CI/testing
    #     minimal = {
    #       cpu = 1;
    #       memory = 2;
    #       disk = 20;
    #       runtime = "docker";
    #       kubernetes = { enabled = false; };
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     # Colima management
    #     "colima-start" = "colima start";
    #     "colima-stop" = "colima stop";
    #     "colima-restart" = "colima restart";
    #     "colima-status" = "colima status";
    #     
    #     # Profile management
    #     "colima-dev" = "colima start --profile development";
    #     "colima-prod" = "colima start --profile production";
    #     "colima-minimal" = "colima start --profile minimal";
    #     
    #     # SSH and debugging
    #     "colima-ssh" = "colima ssh";
    #     "colima-logs" = "colima logs";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # Docker configuration
  # DOCKER_CONFIG = "${config.xdg.configHome}/docker";
  # DOCKER_HOST = "unix:///var/run/docker.sock";  # Default socket
  # BUILDKIT_PROGRESS = "auto";  # BuildKit progress output
  # COMPOSE_DOCKER_CLI_BUILD = "1";  # Use Docker CLI for builds
  
  # Colima configuration
  # COLIMA_HOME = "${config.xdg.configHome}/colima";
  
  # Container development environment
  # TESTCONTAINERS_DOCKER_SOCKET_OVERRIDE = "/var/run/docker.sock";
  
  # --- Integration Notes -----------------------------------------------
  # 1. Docker requires config.json in configs/containers/docker/config.json
  # 2. Colima requires colima.yaml in configs/containers/colima/colima.yaml
  # 3. Both tools integrate with system container runtime management
  # 4. Shell aliases provide convenient shortcuts for common operations
  # 5. Package dependencies: docker-client, colima in packages/devops.nix
  # 6. Consider integration with development environment automation
  
  # --- Shell Functions for Manual Configuration -----------------------
  # These functions provide enhanced container management capabilities
  
  # Docker cleanup function
  # docker-cleanup() {
  #   echo "Cleaning up Docker resources..."
  #   docker container prune -f
  #   docker image prune -f
  #   docker volume prune -f
  #   docker network prune -f
  #   docker system df
  # }
  
  # Docker development environment setup
  # docker-dev-setup() {
  #   local project_name=${1:-$(basename $(pwd))}
  #   echo "Setting up Docker development environment for: $project_name"
  #   
  #   # Create development compose file if it doesn't exist
  #   if [[ ! -f docker-compose.dev.yml ]]; then
  #     cat > docker-compose.dev.yml << EOF
  # version: '3.8'
  # services:
  #   app:
  #     build: .
  #     volumes:
  #       - .:/app
  #       - /app/node_modules
  #     ports:
  #       - "3000:3000"
  #     environment:
  #       - NODE_ENV=development
  # EOF
  #   fi
  #   
  #   docker compose -f docker-compose.dev.yml up -d
  # }
  
  # Colima profile switcher
  # colima-switch() {
  #   local profile=${1:-development}
  #   echo "Switching to Colima profile: $profile"
  #   
  #   colima stop 2>/dev/null || true
  #   colima start --profile "$profile"
  #   colima status
  # }
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create comprehensive Docker Compose templates for different project types
  # 2. Set up Colima profiles for different development scenarios
  # 3. Integrate with container security scanning and compliance tools
  # 4. Add support for multi-architecture container builds
  # 5. Create automation for container lifecycle management
  # 6. Integrate with CI/CD pipelines for container deployment
  # 7. Add support for container orchestration platforms (Kubernetes, etc.)
  # 8. Consider integration with cloud container registries
  
  # --- Usage Examples ------------------------------------------------
  # Common usage patterns for these tools:
  
  # Docker examples:
  # docker run --rm -it ubuntu:latest bash     # Interactive container
  # docker build -t myapp:latest .             # Build image
  # docker compose up -d                       # Start services
  # docker logs -f container_name              # Follow logs
  # docker exec -it container_name bash        # Execute in container
  # docker system prune -a                     # Clean up everything
  
  # Colima examples:
  # colima start                               # Start default runtime
  # colima start --cpu 4 --memory 8           # Start with specific resources
  # colima start --profile development        # Start with profile
  # colima ssh                                 # SSH into VM
  # colima stop                                # Stop runtime
  # colima delete                              # Delete VM and data
  
  # Combined workflow:
  # colima start --profile development        # Start container runtime
  # docker compose up -d                      # Start development services
  # docker logs -f app                        # Monitor application logs
  # docker exec -it app bash                  # Debug inside container
  # colima stop                               # Stop when done
}