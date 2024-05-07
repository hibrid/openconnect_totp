# OpenConnect VPN Service

This project provides a set of scripts to automate the installation and configuration of an OpenConnect VPN service on a Linux system. It allows you to establish a VPN connection to a Cisco ASA firewall using OpenConnect and supports both BASE32 token and TOTP (Time-based One-Time Password) authentication methods.

## Prerequisites

- A Linux system (Ubuntu, Debian, CentOS, or RHEL)
- Access to a Cisco ASA firewall with VPN connectivity
- Valid VPN credentials (username, password, and either BASE32 token or TOTP secret)

## Installation

1. Clone the repository or download the scripts to your Linux system.

2. Make the scripts executable:
   ```
   chmod +x install_vpn_service.sh test_vpn_connection.sh vpn-connection.sh
   ```

3. Create a password file:
   - Choose a secure location for storing the password file, e.g., `/path/to/password.txt`.
   - Open the password file and enter your VPN password on a single line.
   - Save the file and ensure that it has restricted permissions (e.g., `chmod 600 /path/to/password.txt`).

4. Obtain the TOTP secret:
   - If you have a QR code for the TOTP secret:
     - Use a QR code reader browser extension or a mobile app to scan the QR code.
     - The QR code reader will display the TOTP secret as a Base32 encoded string.
   - If you are using Google Authenticator or Authy:
     - Open the Google Authenticator or Authy app on your mobile device.
     - Tap on the "Add" button and select "Scan QR Code".
     - Scan the QR code provided by your VPN administrator.
     - The app will display the TOTP secret and generate time-based one-time passwords.
   - Make note of the TOTP secret for use during the installation process.

5. Run the `install_vpn_service.sh` script with sudo or as root:
   ```
   sudo ./install_vpn_service.sh
   ```

6. Follow the prompts to provide the necessary information:
   - VPN host (example.com)
   - VPN group (TextNow-Employee or TextNow-FullTunnel)
   - VPN username
   - Path to the password file (e.g., `/path/to/password.txt`)
   - Authentication method (BASE32_TOKEN or TOTP_SECRET)
     - If BASE32_TOKEN is selected, enter the BASE32 token
     - If TOTP_SECRET is selected, enter a name for the TOTP secret and the secret itself (obtained in step 4)

7. The script will install the required dependencies (openconnect, totp) if not already installed.

8. The script will create the necessary files and directories:
   - `/etc/vpn-connection.env`: Environment file containing the VPN configuration variables
   - `/etc/systemd/system/my_vpn.service`: SystemD service file for the VPN connection
   - `/usr/local/bin/vpn-connection.sh`: Script that establishes the VPN connection
   - `/etc/totp.json`: File storing the TOTP secret (if TOTP authentication is used)

9. The script will start the VPN service automatically.

## Usage

- To test the VPN connection manually, run the `test_vpn_connection.sh` script:
  ```
  ./test_vpn_connection.sh
  ```

- To manage the VPN service, use the following SystemD commands:
  - Start the service: `sudo systemctl start my_vpn`
  - Stop the service: `sudo systemctl stop my_vpn`
  - Check the service status: `sudo systemctl status my_vpn`

## File Locations

- `install_vpn_service.sh`: Installation script that sets up the VPN service
- `test_vpn_connection.sh`: Script to manually test the VPN connection
- `vpn-connection.sh`: Script that establishes the VPN connection (installed at `/usr/local/bin/vpn-connection.sh`)
- `/etc/vpn-connection.env`: Environment file containing the VPN configuration variables
- `/etc/systemd/system/my_vpn.service`: SystemD service file for the VPN connection
- `/etc/totp.json`: File storing the TOTP secret (if TOTP authentication is used)
- `/path/to/password.txt`: File containing the VPN password (user-specified location)

## Warnings

- The password file (`/path/to/password.txt`) and the TOTP secret file (`/etc/totp.json`) store sensitive information in plain text. It is crucial to ensure that these files have restricted permissions and are only accessible by authorized users.
- Storing passwords and secrets in plain text files poses a security risk. It is strongly recommended to encrypt these files and modify the scripts to decrypt them when needed. Consider using secure encryption mechanisms and storing the encryption keys separately.
- Regularly monitor the access to the password file and TOTP secret file to detect any unauthorized access attempts.
- When providing the path to the password file during the installation process, ensure that the file is stored in a secure location with limited access permissions.
- Keep the TOTP secret confidential and do not share it with anyone. If the secret is compromised, generate a new secret and update it in the VPN configuration.

