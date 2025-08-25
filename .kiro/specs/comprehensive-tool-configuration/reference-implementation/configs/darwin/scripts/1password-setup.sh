#!/usr/bin/env bash
# Title         : 1password-setup.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : configs/darwin/scripts/1password-setup.sh
# ----------------------------------------------------------------------------
# 1Password CLI setup and configuration script for macOS

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Configuration directories
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/op"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/op"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/op"

log_info "Setting up 1Password CLI for macOS..."

# Check if 1Password CLI is installed
if ! command -v op >/dev/null 2>&1; then
    log_error "1Password CLI is not installed. Please install it first:"
    log_info "brew install 1password-cli"
    log_info "Or download from: https://1password.com/downloads/command-line/"
    exit 1
fi

# Create necessary directories
log_info "Creating configuration directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$CACHE_DIR"
mkdir -p "$DATA_DIR"

# Set appropriate permissions
chmod 700 "$CONFIG_DIR"
chmod 700 "$CACHE_DIR"
chmod 700 "$DATA_DIR"

log_success "Directories created successfully"

# Check if 1Password desktop app is installed
if [[ -d "/Applications/1Password 7 - Password Manager.app" ]] || [[ -d "/Applications/1Password.app" ]]; then
    log_info "1Password desktop app detected"
    DESKTOP_APP_AVAILABLE=true
else
    log_warning "1Password desktop app not found. Some features may not work."
    DESKTOP_APP_AVAILABLE=false
fi

# Check current account status
log_info "Checking current 1Password CLI configuration..."

if op account list >/dev/null 2>&1; then
    log_success "1Password CLI is already configured with accounts:"
    op account list
    ACCOUNTS_CONFIGURED=true
else
    log_warning "No 1Password accounts configured"
    ACCOUNTS_CONFIGURED=false
fi

# Interactive account setup if needed
if [[ "$ACCOUNTS_CONFIGURED" == false ]]; then
    echo
    log_info "Setting up 1Password account..."
    echo "You'll need to add your 1Password account to the CLI."
    echo "This requires your:"
    echo "  - Account URL (e.g., https://my.1password.com)"
    echo "  - Email address"
    echo "  - Secret Key"
    echo "  - Master Password"
    echo
    
    read -p "Do you want to add an account now? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Starting account setup..."
        op account add
        
        if op account list >/dev/null 2>&1; then
            log_success "Account added successfully!"
            ACCOUNTS_CONFIGURED=true
        else
            log_error "Account setup failed"
            exit 1
        fi
    else
        log_warning "Skipping account setup. Run 'op account add' manually later."
    fi
fi

# Test CLI functionality
if [[ "$ACCOUNTS_CONFIGURED" == true ]]; then
    log_info "Testing 1Password CLI functionality..."
    
    # Test basic authentication
    if op account get >/dev/null 2>&1; then
        log_success "CLI authentication working"
    else
        log_info "Testing authentication with signin..."
        if op signin >/dev/null 2>&1; then
            log_success "CLI signin successful"
        else
            log_warning "CLI authentication may require manual signin"
        fi
    fi
fi

# Configure SSH agent integration
log_info "Configuring SSH agent integration..."

SSH_CONFIG_DIR="$HOME/.ssh"
SSH_CONFIG_FILE="$SSH_CONFIG_DIR/config"

mkdir -p "$SSH_CONFIG_DIR"
chmod 700 "$SSH_CONFIG_DIR"

# Check if SSH config already has 1Password integration
if [[ -f "$SSH_CONFIG_FILE" ]] && grep -q "1password" "$SSH_CONFIG_FILE"; then
    log_info "SSH config already has 1Password integration"
else
    log_info "Adding 1Password SSH agent configuration..."
    
    # Backup existing SSH config
    if [[ -f "$SSH_CONFIG_FILE" ]]; then
        cp "$SSH_CONFIG_FILE" "$SSH_CONFIG_FILE.backup.$(date +%Y%m%d_%H%M%S)"
        log_info "Backed up existing SSH config"
    fi
    
    # Add 1Password SSH agent configuration
    cat >> "$SSH_CONFIG_FILE" << 'EOF'

# 1Password SSH Agent Integration
Host *
    IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    UseKeychain yes
    AddKeysToAgent yes

EOF
    
    log_success "SSH agent configuration added"
fi

# Configure Git signing (if Git is available)
if command -v git >/dev/null 2>&1; then
    log_info "Configuring Git signing with 1Password..."
    
    # Set up Git to use 1Password for signing
    git config --global gpg.format ssh
    git config --global gpg.ssh.program "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    
    log_success "Git signing configured"
else
    log_warning "Git not found, skipping Git signing configuration"
fi

# Set up shell integration
log_info "Setting up shell integration..."

SHELL_RC_FILE=""
if [[ "$SHELL" == *"zsh"* ]]; then
    SHELL_RC_FILE="$HOME/.zshrc"
elif [[ "$SHELL" == *"bash"* ]]; then
    SHELL_RC_FILE="$HOME/.bashrc"
fi

if [[ -n "$SHELL_RC_FILE" ]]; then
    # Add 1Password CLI completion and aliases
    if ! grep -q "1password-cli" "$SHELL_RC_FILE" 2>/dev/null; then
        cat >> "$SHELL_RC_FILE" << 'EOF'

# 1Password CLI Integration
if command -v op >/dev/null 2>&1; then
    # Enable completion
    eval "$(op completion $(basename $SHELL))"
    
    # Useful aliases
    alias op-signin='eval $(op signin)'
    alias op-list='op item list'
    alias op-get='op item get'
    alias op-password='op item get --field password'
    alias op-totp='op item get --otp'
fi

EOF
        log_success "Shell integration added to $SHELL_RC_FILE"
    else
        log_info "Shell integration already configured"
    fi
fi

# Create useful scripts
log_info "Creating utility scripts..."

# Create op-quick script for common operations
cat > "$HOME/.local/bin/op-quick" << 'EOF'
#!/usr/bin/env bash
# Quick 1Password CLI operations

case "$1" in
    "password"|"pass"|"p")
        if [[ -z "$2" ]]; then
            echo "Usage: op-quick password <item-name>"
            exit 1
        fi
        op item get "$2" --field password
        ;;
    "totp"|"otp"|"2fa")
        if [[ -z "$2" ]]; then
            echo "Usage: op-quick totp <item-name>"
            exit 1
        fi
        op item get "$2" --otp
        ;;
    "username"|"user"|"u")
        if [[ -z "$2" ]]; then
            echo "Usage: op-quick username <item-name>"
            exit 1
        fi
        op item get "$2" --field username
        ;;
    "search"|"find"|"s")
        if [[ -z "$2" ]]; then
            echo "Usage: op-quick search <query>"
            exit 1
        fi
        op item list --categories Login,Password,Database,Server | grep -i "$2"
        ;;
    "list"|"ls"|"l")
        op item list --categories Login,Password,Database,Server
        ;;
    *)
        echo "1Password CLI Quick Operations"
        echo "Usage: op-quick <command> [args]"
        echo ""
        echo "Commands:"
        echo "  password|pass|p <item>    Get password for item"
        echo "  totp|otp|2fa <item>       Get TOTP code for item"
        echo "  username|user|u <item>    Get username for item"
        echo "  search|find|s <query>     Search for items"
        echo "  list|ls|l                 List all login items"
        ;;
esac
EOF

chmod +x "$HOME/.local/bin/op-quick"
log_success "Created op-quick utility script"

# Test SSH agent if configured
if [[ "$DESKTOP_APP_AVAILABLE" == true ]]; then
    log_info "Testing SSH agent integration..."
    
    SSH_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    if [[ -S "$SSH_AGENT_SOCK" ]]; then
        log_success "1Password SSH agent socket found"
        
        # Test SSH agent
        if SSH_AUTH_SOCK="$SSH_AGENT_SOCK" ssh-add -l >/dev/null 2>&1; then
            log_success "SSH agent is working"
        else
            log_info "SSH agent found but no keys loaded (this is normal)"
        fi
    else
        log_warning "1Password SSH agent socket not found"
        log_info "Make sure SSH agent is enabled in 1Password preferences"
    fi
fi

# Create status check script
cat > "$HOME/.local/bin/op-status" << 'EOF'
#!/usr/bin/env bash
# Check 1Password CLI status

echo "1Password CLI Status Check"
echo "=========================="

# Check if CLI is installed
if command -v op >/dev/null 2>&1; then
    echo "✓ 1Password CLI installed: $(op --version)"
else
    echo "✗ 1Password CLI not installed"
    exit 1
fi

# Check accounts
echo ""
echo "Configured Accounts:"
if op account list >/dev/null 2>&1; then
    op account list
else
    echo "✗ No accounts configured"
fi

# Check authentication
echo ""
echo "Authentication Status:"
if op account get >/dev/null 2>&1; then
    echo "✓ Authenticated"
else
    echo "✗ Not authenticated (run 'op signin')"
fi

# Check SSH agent
echo ""
echo "SSH Agent Integration:"
SSH_AGENT_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
if [[ -S "$SSH_AGENT_SOCK" ]]; then
    echo "✓ SSH agent socket found"
    if SSH_AUTH_SOCK="$SSH_AGENT_SOCK" ssh-add -l >/dev/null 2>&1; then
        echo "✓ SSH agent working with keys"
    else
        echo "! SSH agent working but no keys loaded"
    fi
else
    echo "✗ SSH agent socket not found"
fi

# Check directories
echo ""
echo "Configuration Directories:"
echo "Config: ${XDG_CONFIG_HOME:-$HOME/.config}/op"
echo "Cache:  ${XDG_CACHE_HOME:-$HOME/.cache}/op"
echo "Data:   ${XDG_DATA_HOME:-$HOME/.local/share}/op"

# Check desktop app
echo ""
echo "Desktop App:"
if [[ -d "/Applications/1Password 7 - Password Manager.app" ]] || [[ -d "/Applications/1Password.app" ]]; then
    echo "✓ 1Password desktop app installed"
else
    echo "✗ 1Password desktop app not found"
fi
EOF

chmod +x "$HOME/.local/bin/op-status"
log_success "Created op-status utility script"

# Final summary
echo
log_success "1Password CLI setup completed!"

cat << EOF

${GREEN}Setup Summary:${NC}
✓ Configuration directories created
✓ SSH agent integration configured
✓ Git signing configured (if Git available)
✓ Shell integration added
✓ Utility scripts created

${BLUE}Useful Commands:${NC}
- op-status          Check 1Password CLI status
- op-quick password  Get password for an item
- op-quick totp      Get TOTP code for an item
- op signin          Sign in to your account
- op item list       List all items

${BLUE}Next Steps:${NC}
1. Restart your terminal to load shell integration
2. Run 'op-status' to verify everything is working
3. Enable SSH agent in 1Password app preferences
4. Add SSH keys to 1Password for seamless Git operations

${YELLOW}Security Notes:${NC}
- Keep your Secret Key and Master Password secure
- Enable biometric unlock in 1Password app
- Regularly review and rotate your passwords
- Use unique passwords for all accounts

EOF