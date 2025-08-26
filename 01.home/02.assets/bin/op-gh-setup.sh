#!/usr/bin/env bash
# Title         : 01.home/00.core/configs/git/op-gh-setup.sh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : /01.home/00.core/configs/git/op-gh-setup.sh
# ----------------------------------------------------------------------------
# Setup gh CLI with 1Password integration using dynamic lookup

set -euo pipefail

# --- Configuration Setup ----------------------------------------------------
CONFIG_DIR="$HOME/.config/op/plugins"
CONFIG_FILE="$CONFIG_DIR/gh.json"

# Ensure config directory exists
mkdir -p "$CONFIG_DIR"

# --- 1Password Lookups ------------------------------------------------------
# Get 1Password account ID
ACCOUNT_ID=$(op account get --format=json | jq -r '.id')

# Find the Tokens vault
VAULT_ID=$(op vault get "Tokens" --format=json | jq -r '.id')

# Find the Github Token item
ITEM_ID=$(op item get "Github Token" --vault="Tokens" --format=json | jq -r '.id')

# --- Generate Configuration -------------------------------------------------
cat > "$CONFIG_FILE" <<EOF
{
	"account_id": "$ACCOUNT_ID",
	"entrypoint": [
		"gh"
	],
	"credentials": [
		{
			"plugin": "github",
			"credential_type": "personal_access_token",
			"usage_id": "personal_access_token",
			"vault_id": "$VAULT_ID",
			"item_id": "$ITEM_ID"
		}
	]
}
EOF

echo "✅ gh CLI configured with 1Password integration"
echo "   Vault: Tokens"
echo "   Item: Github Token"
echo "   Config: $CONFIG_FILE"