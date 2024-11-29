#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Set key variables
OS_NAME="Enipla"
RELEASE_NAME="Begone"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Set the paths for the logo and background
LOGO_PATH="$SCRIPT_DIR/hd_enipla_logo_icon_transparent.png"
BACKGROUND_PATH="$SCRIPT_DIR/enipla_background.png"

# Path to first-login script
FIRST_LOGIN_SCRIPT="/etc/enipla/first-login.sh"

# --- Verify Required Files ---
if [ ! -f "$LOGO_PATH" ]; then
    echo "Error: Logo file $LOGO_PATH not found."
    exit 1
fi

if [ ! -f "$BACKGROUND_PATH" ]; then
    echo "Error: Background file $BACKGROUND_PATH not found."
    exit 1
fi

# --- Branding changes ---
echo "Welcome to Enipla \"Begone\" OS" > /etc/motd
echo "" >> /etc/motd
echo "An OS powered by hopes and dreams" >> /etc/motd

sed -i "s/Debian GNU\/Linux/Enipla Begone/g" /etc/issue
sed -i "s/Debian GNU\\/Linux/Enipla Begone/g" /etc/os-release
sed -i "s/PRETTY_NAME=\"Debian GNU\\/Linux/PRETTY_NAME=\"Enipla Begone/g" /etc/os-release
sed -i "s/NAME=\"Debian GNU\\/Linux/NAME=\"Enipla Begone/g" /etc/os-release

# Change hostname
echo "enipla" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1   enipla/g" /etc/hosts

# Update system and upgrade
apt-get update && apt-get dist-upgrade -y

# Install Openbox, LightDM, and utilities
apt-get install -y openbox lightdm lightdm-gtk-greeter xterm pcmanfm tint2 neofetch feh xcompmgr firefox-esr vlc gedit

# --- Copy logo and background to global locations ---
mkdir -p /usr/share/backgrounds
mkdir -p /usr/share/icons
cp "$LOGO_PATH" /usr/share/icons/enipla_logo.png
cp "$BACKGROUND_PATH" /usr/share/backgrounds/enipla_background.png
chmod 644 /usr/share/icons/enipla_logo.png
chmod 644 /usr/share/backgrounds/enipla_background.png

# --- Configure LightDM ---
sed -i "s|background=.*|background=/usr/share/backgrounds/enipla_background.png|g" /etc/lightdm/lightdm-gtk-greeter.conf

# --- Configure Openbox ---
mkdir -p ~/.config/openbox
cat > ~/.config/openbox/autostart <<EOL
# Set wallpaper using feh
feh --bg-scale "/usr/share/backgrounds/enipla_background.png" &
# Start Tint2 panel
tint2 &
# Launch file manager
pcmanfm --desktop &
EOL
chmod +x ~/.config/openbox/autostart

# --- Set the Openbox menu logo ---
mkdir -p ~/.themes/enipla/
ln -sf /usr/share/icons/enipla_logo.png ~/.themes/enipla/logo.png

# --- Add a custom greeting with Neofetch ---
echo "neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6" >> ~/.bashrc
echo "echo 'Welcome to $OS_NAME \"$RELEASE_NAME\"'" >> ~/.bashrc

# --- First-Login Script Setup ---
mkdir -p /etc/enipla/
cat > "$FIRST_LOGIN_SCRIPT" <<'EOF'
#!/bin/bash
# Install additional software
apt-get update
apt-get install -y flatpak abiword gnumeric sylpheed zathura mpv xmms mtpaint gftp leafpad zzzfm peazip
# Install Flatpak apps
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --noninteractive -y flathub com.brave.Browser
flatpak install --noninteractive -y flathub app.drey.Warp
flatpak install --noninteractive -y flathub org.kde.isoimagewriter
flatpak install --noninteractive -y flathub com.valvesoftware.Steam
# Perform additional updates
apt-get upgrade -y
apt-get autoremove -y
# Remove this script to ensure it runs only once
rm -- "$0"
EOF
chmod +x "$FIRST_LOGIN_SCRIPT"

# Append first-login script to new users' .bashrc
echo "$FIRST_LOGIN_SCRIPT" >> /etc/skel/.bashrc

# Note: Skipping systemctl restart lightdm as it's not supported in Cubic's environment
