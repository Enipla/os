#!/bin/bash

# Set key variables
OS_NAME="Enipla"
RELEASE_NAME="Begone"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Set the paths for the logo and background (relative to the script's location)
LOGO_PATH="$SCRIPT_DIR/hd_enipla_logo_icon_transparent.png"
BACKGROUND_PATH="$SCRIPT_DIR/enipla_background.png"

# Path to first-login script
FIRST_LOGIN_SCRIPT="/etc/enipla/first-login.sh"

# --- Branding changes ---

# Edit /etc/motd
echo "Welcome to Enipla \"Begone\" OS" > /etc/motd
echo "" >> /etc/motd
echo "An OS powered by hopes and dreams" >> /etc/motd

# Edit /etc/issue
sed -i "s/Debian GNU\/Linux/Enipla Begone/g" /etc/issue

# Edit /etc/os-release
sed -i "s/Debian GNU\\/Linux/Enipla Begone/g" /etc/os-release
sed -i "s/PRETTY_NAME=\"Debian GNU\\/Linux/PRETTY_NAME=\"Enipla Begone/g" /etc/os-release
sed -i "s/NAME=\"Debian GNU\\/Linux/NAME=\"Enipla Begone/g" /etc/os-release

# Change hostname
echo "enipla" > /etc/hostname
hostnamectl set-hostname enipla

# Update package lists
apt-get update

# Install Openbox, basic utilities, LightDM, and NeoFetch
apt-get install -y openbox lightdm lightdm-gtk-greeter xterm pcmanfm tint2 neofetch

# Install basic applications
apt-get install -y firefox-esr vlc gedit

# --- LightDM Configuration ---
# Set the background image
sed -i "s|#background=.*|background=$BACKGROUND_PATH|g" /etc/lightdm/lightdm-gtk-greeter.conf

# --- Openbox Configuration ---
# Set up autostart for Openbox
mkdir -p ~/.config/openbox
cat > ~/.config/openbox/autostart <<EOL
# Set wallpaper
feh --bg-scale "$BACKGROUND_PATH" &

# Start tint2 panel
tint2 &

# Launch basic utilities
pcmanfm --desktop &
EOL

# Set the Openbox menu logo
mkdir -p ~/.themes/enipla/
cp "$LOGO_PATH" ~/.themes/enipla/logo.png

# --- Add a custom greeting with Neofetch ---
echo "neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6" >> ~/.bashrc
echo "echo 'Welcome to $OS_NAME \"$RELEASE_NAME\"'" >> ~/.bashrc

# --- First-Login Script Setup ---
# Create a directory for the script
mkdir -p /etc/enipla/

# Create the first-login script
cat > "$FIRST_LOGIN_SCRIPT" <<'EOF'
#!/bin/bash

# Install additional software
apt-get install -y flatpak abiword gnumeric sylpheed zathura mpv xmms mtpaint gftp leafpad zzzfm peazip

# Install Flatpak apps
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.brave.Browser
flatpak install -y flathub app.drey.Warp
flatpak install -y flathub org.kde.isoimagewriter
flatpak install -y flathub com.valvesoftware.Steam

# Perform additional setup steps (customize as needed)
# For example, update all system packages
apt-get upgrade -y

# Cleanup tasks
apt-get autoremove -y

# Remove this script to ensure it runs only once
rm -- "$0"
EOF

# Make the first-login script executable
chmod +x "$FIRST_LOGIN_SCRIPT"

# Set up first-login execution for new users
echo "$FIRST_LOGIN_SCRIPT" >> /etc/skel/.bashrc

# Restart LightDM to apply changes
systemctl restart lightdm
