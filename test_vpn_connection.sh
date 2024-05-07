#!/bin/bash

# Path to the environment file
ENV_FILE="/etc/vpn-connection.env"

# Check if the environment file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Environment file not found: $ENV_FILE"
    exit 1
fi


# Source the environment file
set -a
. "$ENV_FILE"
set +a

# Check if the required variables are set
if [[ -z "$GROUP" || -z "$USERNAME" || -z "$PASSWORD_FILE" || -z "$HOST" ]]; then
    echo "Error: Required environment variables (HOST, GROUP, USERNAME, PASSWORD_FILE) are not set."
    exit 1
fi

# Check if either BASE32_TOKEN or TOTP_SECRET_NAME is provided
if [[ -z "$BASE32_TOKEN" && -z "$TOTP_SECRET_NAME" ]]; then
    echo "Error: Neither BASE32_TOKEN nor TOTP_SECRET is provided."
    exit 1
fi

# Check if the password file exists
if [[ ! -f "$PASSWORD_FILE" ]]; then
    echo "Error: Password file not found at $PASSWORD_FILE"
    exit 1
fi

# Path to the vpn-connection.sh script
VPN_SCRIPT_PATH="/usr/local/bin/vpn-connection.sh"

# Check if the vpn-connection.sh script exists
if [ ! -f "$VPN_SCRIPT_PATH" ]; then
    echo "vpn-connection.sh script not found: $VPN_SCRIPT_PATH"
    exit 1
fi

# Run the vpn-connection.sh script
"$VPN_SCRIPT_PATH"

# Check the exit status of the vpn-connection.sh script
if [ $? -eq 0 ]; then
    echo "VPN connection established successfully."
else
    echo "Failed to establish VPN connection."
fi
