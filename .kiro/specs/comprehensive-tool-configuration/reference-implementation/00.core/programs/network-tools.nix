# Title         : network-tools.nix
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/programs/network-tools.nix
# ----------------------------------------------------------------------------
# Network diagnostic and utility tools: xh (HTTP client), doggo (DNS client),
# and gping (ping with visualization). These tools provide modern interfaces
# for network testing, API interaction, and connectivity diagnostics.

{
  config,
  lib,
  pkgs,
  ...
}:

{
  programs = {
    # --- XH HTTP Client --------------------------------------------
    # Modern HTTP client inspired by HTTPie with improved performance
    # Provides intuitive syntax for API testing and HTTP interactions
    # TODO: No home-manager module available - requires config file
    
    # xh = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- Default Options ---------------------------------
    #     # Default behavior for HTTP requests
    #     default_options = {
    #       # Output format (auto, json, headers, body, verbose)
    #       print = "HhBb";  # Headers and body for both request and response
    #       
    #       # Follow redirects automatically
    #       follow = true;
    #       
    #       # Maximum number of redirects to follow
    #       max_redirects = 10;
    #       
    #       # Request timeout in seconds
    #       timeout = 30;
    #       
    #       # Verify SSL certificates
    #       verify = true;
    #       
    #       # Pretty print JSON responses
    #       pretty = "auto";  # auto, all, colors, format, none
    #       
    #       # Default HTTP method when not specified
    #       default_method = "GET";
    #     };
    #     
    #     # --- Authentication Settings -------------------------
    #     # Default authentication methods
    #     auth = {
    #       # Store authentication tokens securely
    #       store_tokens = true;
    #       
    #       # Default authentication type
    #       default_auth_type = "bearer";
    #     };
    #     
    #     # --- Session Management ------------------------------
    #     # HTTP session configuration
    #     session = {
    #       # Default session directory
    #       session_dir = "${config.xdg.configHome}/xh/sessions";
    #       
    #       # Automatically save successful requests to session
    #       auto_save = false;
    #       
    #       # Session file format
    #       format = "json";
    #     };
    #     
    #     # --- Output Configuration ----------------------------
    #     # Response formatting and display
    #     output = {
    #       # Color output
    #       colors = {
    #         auto = true;
    #         theme = "auto";  # auto, dark, light
    #       };
    #       
    #       # Syntax highlighting
    #       highlight = {
    #         style = "monokai";
    #         line_numbers = false;
    #       };
    #       
    #       # Paging for long responses
    #       pager = {
    #         enabled = "auto";  # auto, always, never
    #         command = "less -R";
    #       };
    #     };
    #     
    #     # --- Request Configuration ---------------------------
    #     # Default request headers and behavior
    #     request = {
    #       # Default headers to include
    #       default_headers = {
    #         "User-Agent" = "xh/parametric-forge";
    #         "Accept" = "application/json, */*";
    #       };
    #       
    #       # Default query parameters
    #       default_params = {};
    #       
    #       # Body formatting
    #       body = {
    #         # Default content type for JSON data
    #         json_content_type = "application/json";
    #         
    #         # Form data encoding
    #         form_content_type = "application/x-www-form-urlencoded";
    #       };
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     # Basic HTTP methods
    #     "GET" = "xh GET";
    #     "POST" = "xh POST";
    #     "PUT" = "xh PUT";
    #     "DELETE" = "xh DELETE";
    #     "PATCH" = "xh PATCH";
    #     "HEAD" = "xh HEAD";
    #     "OPTIONS" = "xh OPTIONS";
    #     
    #     # Common patterns
    #     "http" = "xh";
    #     "https" = "xh --verify=yes";
    #     "curl" = "xh";  # Drop-in replacement for simple curl usage
    #     
    #     # JSON operations
    #     "json-get" = "xh GET Accept:application/json";
    #     "json-post" = "xh POST Content-Type:application/json";
    #   };
    # };

    # --- Doggo DNS Client ------------------------------------------
    # Modern DNS lookup tool with support for multiple protocols
    # Provides colored output and comprehensive DNS record information
    # TODO: No home-manager module available - requires config file
    
    # doggo = {
    #   enable = true;
    #   
    #   # --- Core Configuration --------------------------------------
    #   settings = {
    #     # --- DNS Server Configuration ------------------------
    #     # Default DNS servers to use
    #     resolvers = [
    #       {
    #         name = "cloudflare";
    #         address = "1.1.1.1:53";
    #         type = "udp";
    #       }
    #       {
    #         name = "cloudflare-doh";
    #         address = "https://cloudflare-dns.com/dns-query";
    #         type = "doh";
    #       }
    #       {
    #         name = "quad9";
    #         address = "9.9.9.9:53";
    #         type = "udp";
    #       }
    #       {
    #         name = "google";
    #         address = "8.8.8.8:53";
    #         type = "udp";
    #       }
    #     ];
    #     
    #     # --- Query Configuration -----------------------------
    #     # Default query settings
    #     query = {
    #       # Default query type
    #       type = "A";
    #       
    #       # Default query class
    #       class = "IN";
    #       
    #       # Query timeout in seconds
    #       timeout = 5;
    #       
    #       # Number of retries
    #       retries = 3;
    #       
    #       # Use IPv6 for queries
    #       ipv6 = false;
    #       
    #       # Reverse DNS lookups
    #       reverse = false;
    #     };
    #     
    #     # --- Output Configuration ----------------------------
    #     # Response formatting and display
    #     output = {
    #       # Output format (table, json, yaml, xml)
    #       format = "table";
    #       
    #       # Colorize output
    #       color = true;
    #       
    #       # Show query time
    #       time = true;
    #       
    #       # Show additional sections (answer, authority, additional)
    #       sections = {
    #         answer = true;
    #         authority = false;
    #         additional = false;
    #       };
    #       
    #       # Compact output format
    #       short = false;
    #     };
    #     
    #     # --- Protocol Configuration -------------------------
    #     # DNS protocol settings
    #     protocol = {
    #       # Default protocol (udp, tcp, doh, dot, doq)
    #       default = "udp";
    #       
    #       # TCP fallback for truncated responses
    #       tcp_fallback = true;
    #       
    #       # DNSSEC validation
    #       dnssec = false;
    #       
    #       # EDNS0 support
    #       edns0 = true;
    #       
    #       # Buffer size for EDNS0
    #       buffer_size = 1232;
    #     };
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     # Basic lookups
    #     "dig" = "doggo";
    #     "nslookup" = "doggo";
    #     
    #     # Record type shortcuts
    #     "a" = "doggo A";
    #     "aaaa" = "doggo AAAA";
    #     "mx" = "doggo MX";
    #     "txt" = "doggo TXT";
    #     "cname" = "doggo CNAME";
    #     "ns" = "doggo NS";
    #     "soa" = "doggo SOA";
    #     
    #     # Protocol shortcuts
    #     "doh" = "doggo --type doh @cloudflare-doh";
    #     "dot" = "doggo --type dot";
    #     
    #     # Utility shortcuts
    #     "reverse" = "doggo --reverse";
    #     "trace" = "doggo --trace";
    #   };
    # };

    # --- Gping Network Ping Tool ----------------------------------
    # Ping tool with real-time graph visualization
    # Provides visual feedback for network connectivity and latency
    # Note: No configuration file support - pure command-line tool
    
    # gping = {
    #   enable = true;
    #   
    #   # --- Default Configuration ------------------------------
    #   # Default options for ping operations
    #   defaultOptions = [
    #     "--buffer" "100"      # Buffer size for graph history
    #     "--watch-interval" "1" # Update interval in seconds
    #   ];
    #   
    #   # --- Display Configuration ------------------------------
    #   # Graph and output formatting
    #   display = {
    #     # Use simple characters for better compatibility
    #     simple_graphics = false;
    #     
    #     # Color scheme for the graph
    #     color_scheme = "auto";  # auto, dark, light
    #     
    #     # Show statistics
    #     show_stats = true;
    #     
    #     # Graph height in terminal lines
    #     graph_height = 10;
    #   };
    #   
    #   # --- Network Configuration -----------------------------
    #   # Ping behavior settings
    #   network = {
    #     # Default ping interval in seconds
    #     interval = 1.0;
    #     
    #     # Ping timeout in seconds
    #     timeout = 3.0;
    #     
    #     # Packet size in bytes
    #     packet_size = 56;
    #     
    #     # Use IPv4 by default
    #     ipv4 = true;
    #     
    #     # Use IPv6 when specified
    #     ipv6 = false;
    #   };
    #   
    #   # --- Shell Integration ----------------------------------
    #   # Create convenient aliases for common operations
    #   aliases = {
    #     "ping" = "gping";
    #     "ping4" = "gping -4";
    #     "ping6" = "gping -6";
    #     "pingfast" = "gping --watch-interval 0.5";
    #     "pingslow" = "gping --watch-interval 2";
    #   };
    # };
  };

  # --- Environment Variables for Manual Configuration -------------------
  # These environment variables configure the tools until home-manager modules
  # are available. They should be moved to environment.nix in actual implementation.
  
  # XH configuration (XDG compliant)
  # XH_CONFIG_DIR = "${config.xdg.configHome}/xh";
  # XH_HTTPIE_COMPAT_MODE = "true";
  
  # Doggo configuration (XDG compliant)
  # DOGGO_CONFIG = "${config.xdg.configHome}/doggo/config.yaml";
  
  # Color and output settings
  # NO_COLOR = "";  # Enable colors (empty = colors enabled)
  # FORCE_COLOR = "1";  # Force colors even when not in terminal
  
  # --- Integration Notes -----------------------------------------------
  # 1. XH requires config.json in configs/network/xh/config.json
  # 2. Doggo requires config.yaml in configs/network/doggo/config.yaml
  # 3. Gping has no config files - pure command-line tool
  # 4. All tools support shell aliases for convenient access
  # 5. Package dependencies: xh, doggo, gping in packages/network-tools.nix
  # 6. Consider integration with network monitoring and alerting
  
  # --- Shell Aliases for Manual Configuration -------------------------
  # These aliases provide convenient shortcuts until programs modules are available
  
  # XH aliases
  # alias http='xh'
  # alias https='xh --verify=yes'
  # alias GET='xh GET'
  # alias POST='xh POST'
  # alias PUT='xh PUT'
  # alias DELETE='xh DELETE'
  # alias json-get='xh GET Accept:application/json'
  # alias json-post='xh POST Content-Type:application/json'
  
  # Doggo aliases
  # alias dig='doggo'
  # alias nslookup='doggo'
  # alias dns='doggo'
  # alias a='doggo A'
  # alias aaaa='doggo AAAA'
  # alias mx='doggo MX'
  # alias txt='doggo TXT'
  # alias cname='doggo CNAME'
  # alias ns='doggo NS'
  
  # Gping aliases
  # alias ping='gping'
  # alias ping4='gping -4'
  # alias ping6='gping -6'
  
  # --- TODO: Future Improvements --------------------------------------
  # 1. Create XH session templates for common API endpoints
  # 2. Set up Doggo resolver profiles for different use cases
  # 3. Integrate with network monitoring and alerting systems
  # 4. Create wrapper scripts for common network diagnostic workflows
  # 5. Add integration with VPN and proxy configurations
  # 6. Consider integration with security scanning and testing tools
  # 7. Add support for batch operations and automation
  
  # --- Usage Examples ------------------------------------------------
  # Common usage patterns for these tools:
  
  # XH examples:
  # xh GET httpbin.org/json                    # Simple GET request
  # xh POST httpbin.org/post name=value       # POST with form data
  # xh PUT api.example.com/users/1 name=John  # PUT request with JSON
  # xh --session=api GET api.example.com/auth # Use saved session
  # xh --print=HhBb GET example.com           # Show headers and body
  
  # Doggo examples:
  # doggo example.com                          # Basic A record lookup
  # doggo MX example.com                       # Mail server lookup
  # doggo @1.1.1.1 example.com               # Use specific DNS server
  # doggo --type doh example.com              # DNS over HTTPS
  # doggo --reverse 8.8.8.8                   # Reverse DNS lookup
  
  # Gping examples:
  # gping google.com                           # Ping with graph
  # gping google.com cloudflare.com           # Ping multiple hosts
  # gping -4 example.com                       # Force IPv4
  # gping --watch-interval 0.5 example.com    # Fast ping updates
}