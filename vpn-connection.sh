#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Set the PATH environment variable to include the necessary directories
export PATH="$PATH:/usr/local/go/bin:/root/go/bin"

# Check if the required variables are set as environment variables
if [[ -z "$GROUP" || -z "$USERNAME" || -z "$PASSWORD_FILE" ]]; then
    echo "Error: Required environment variables (GROUP, USERNAME, PASSWORD_FILE) are not set."
    exit 1
fi

# Check if either BASE32_TOKEN or TOTP_SECRET_NAME is provided
if [[ -z "$BASE32_TOKEN" && -z "$TOTP_SECRET_NAME" ]]; then
    echo "Error: Neither BASE32_TOKEN nor TOTP_SECRET_NAME is provided."
    exit 1
fi

# Check if the password file exists
if [[ ! -f "$PASSWORD_FILE" ]]; then
    echo "Error: Password file not found at $PASSWORD_FILE"
    exit 1
fi

PASSWORD=$(cat "$PASSWORD_FILE")
HOST="$HOST"


# If BASE32_TOKEN is provided, use it
if [[ -n "$BASE32_TOKEN" ]]; then
    echo "$PASSWORD" | openconnect "$HOST" -u "$USERNAME" --form-entry main:group_list="${GROUP}" --passwd-on-stdin --useragent 'AnyConnect Windows 4.10.06079' --os=mac-intel --token-mode=totp --token-secret=base32:"$BASE32_TOKEN"
    exit 0
fi

# If TOTP_SECRET is provided, use the totp approach
if [[ -n "$TOTP_SECRET_NAME" ]]; then
	 # Check if totp is installed
    if ! command_exists totp; then
        # Check if go is installed
        if ! command_exists go; then
            echo "Error: Failed to find go."
            exit 1
        fi

        # Validate the installation
        if ! command_exists totp; then
            echo "Error: Failed to find totp."
            exit 1
        fi
    fi
    
    echo "$PASSWORD" | openconnect "$HOST" -u "$USERNAME" --form-entry main:group_list="${GROUP}" --passwd-on-stdin --form-entry challenge:answer=$(totp "$TOTP_SECRET_NAME" --file=/etc/totp.json) --useragent 'AnyConnect Windows 4.10.06079' --os=mac-intel
    exit 0
fi
