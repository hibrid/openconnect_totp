#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if openconnect is installed
if ! command_exists openconnect; then
    echo "openconnect is not installed. Installing openconnect..."
    apt update
    apt install -y openconnect
fi

# Check if running in an LXC container
if grep -q "container=lxc" /proc/1/environ; then
    echo "Running in an LXC container."

    # Get the container ID
    container_id=$(cat /proc/self/cgroup | grep -oP '(?<=/)lxc/\K.*')

    # Print instructions for the user to run on the host hypervisor
    echo "Please run the following command on the host hypervisor (Proxmox) to update the container configuration:"
    echo "echo -e 'lxc.cgroup2.devices.allow: c 10:200 rwm\nlxc.mount.entry: /dev/net dev/net none bind,create=dir' >> /etc/pve/lxc/$container_id.conf"
    echo "After updating the configuration, restart the LXC container."
fi

# Check if /etc/resolv.conf is a symbolic link to /run/resolvconf/resolv.conf
if [ ! -L /etc/resolv.conf ] || [ "$(readlink /etc/resolv.conf)" != "/run/resolvconf/resolv.conf" ]; then
    echo "Fixing /etc/resolv.conf symbolic link..."
    dpkg-reconfigure -f noninteractive resolvconf
fi

# Prompt the user for details
read -p "Enter the VPN host (example.com): " HOST
read -p "Enter the VPN group (TextNow-Employee|TextNow-FullTunnel): " GROUP
read -p "Enter your VPN username: " USERNAME

# Validate the password file path
while true; do
    read -p "Enter the path to the password file: " PASSWORD_FILE
    if [ -f "$PASSWORD_FILE" ]; then
        break
    else
        echo "Password file not found at $PASSWORD_FILE. Please enter a valid path."
    fi
done

echo "Choose the authentication method:"
echo "1. BASE32_TOKEN"
echo "2. TOTP_SECRET"
read -p "Enter your choice (1 or 2): " AUTH_CHOICE

if [[ "$AUTH_CHOICE" == "1" ]]; then
    read -p "Enter your BASE32_TOKEN: " BASE32_TOKEN
elif [[ "$AUTH_CHOICE" == "2" ]]; then
    # Check if totp is installed
    if ! command_exists totp; then
        echo "Installing totp..."
        # Clone the totp repository
        git clone https://github.com/arcanericky/totp.git
        cd totp

        # Determine the platform
    	case "$(uname -m)" in
           x86_64)
            	PLATFORM="linux-amd64"
            	BINARY_NAME="totp-linux-amd64"
            	;;
           arm)
            	PLATFORM="linux-arm"
            	BINARY_NAME="totp-linux-arm"
            	;;
           aarch64)
            	PLATFORM="linux-arm64"
            	BINARY_NAME="totp-linux-arm64"
            	;;
           *)
            	echo "Unsupported platform"
            	exit 1
          	  ;;
    	esac

        # Build the totp binary
        make $PLATFORM

        # Move the totp binary to ~/go/bin
        mkdir -p ~/go/bin
        mv /usr/local/bin/$BINARY_NAME ~/go/bin/totp

        # Clean up
        cd ..
        rm -rf totp

        # Update the PATH environment variable
        export PATH=$PATH:~/go/bin
    fi

    read -p "Enter a name for your TOTP secret: " TOTP_SECRET_NAME
    read -p "Enter your TOTP secret: " TOTP_SECRET

    # Configure the TOTP secret
    totp config add "$TOTP_SECRET_NAME" "$TOTP_SECRET" --file=/etc/totp.json
else
    echo "Invalid choice. Exiting."
    exit 1
fi

# Create the environment file
ENV_FILE="/etc/vpn-connection.env"
cat > "$ENV_FILE" << EOL
GROUP="$GROUP"
USERNAME="$USERNAME"
PASSWORD_FILE="$PASSWORD_FILE"
BASE32_TOKEN="$BASE32_TOKEN"
TOTP_SECRET_NAME="$TOTP_SECRET_NAME"
HOST="$HOST"
EOL

# Default paths for the service file and vpn-connection.sh
SERVICE_FILE_PATH="/etc/systemd/system/my_vpn.service"
VPN_SCRIPT_PATH="/usr/local/bin/vpn-connection.sh"

# Create the service file if it doesn't exist
if [ ! -f "$SERVICE_FILE_PATH" ]; then
    cat > "$SERVICE_FILE_PATH" << EOL
[Unit]
Description=Openconnect VPN
After=network-online.target
Conflicts=shutdown.target sleep.target

[Service]
Environment=PATH=/usr/local/go/bin:/usr/local/bin:/usr/sbin:/usr/bin:/bin
Type=forking
EnvironmentFile=/path/to/vpn-connection.env
ExecStart=/path/to/vpn-connection.sh
TimeoutStartSec=120s
KillSignal=SIGINT
Restart=on-failure
RestartSec=10s

[Install]
WantedBy=multi-user.target
EOL
fi

# Update the service file with the correct paths
sed -i "s|/path/to/vpn-connection.env|$ENV_FILE|" "$SERVICE_FILE_PATH"
sed -i "s|/path/to/vpn-connection.sh|$VPN_SCRIPT_PATH|" "$SERVICE_FILE_PATH"


# Install the service file
cp "$SERVICE_FILE_PATH" /etc/systemd/system/

# Install the vpn-connection.sh script
cp "vpn-connection.sh" "$VPN_SCRIPT_PATH"
chmod +x "$VPN_SCRIPT_PATH"

# Reload the systemd daemon, enable, and start the service
systemctl daemon-reload
systemctl enable my_vpn
systemctl start my_vpn --no-block
systemctl status my_vpn  --no-block

echo "VPN service installed and started successfully."
