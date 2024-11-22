#!/bin/bash

# Set key variables
OS_NAME="Enipla"
RELEASE_NAME="Begone"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Set the paths for the logo and background (relative to the script's location)
LOGO_PATH="$SCRIPT_DIR/hd_enipla_logo_icon_transparent.png"
BACKGROUND_PATH="$SCRIPT_DIR/enipla_background.png"

# Update package lists
apt-get update

# Install LXQT, LXQT Core, LightDM and NeoFetch
apt-get install -y lxqt lxqt-core lightdm neofetch

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

# --- LightDM Configuration ---
# Set the background image
sed -i "s/#background=/background=$BACKGROUND_PATH/g" /etc/lightdm/lightdm-gtk-greeter.conf

# --- LXQT Configuration ---
mkdir -p /usr/share/lxqt/themes/lxqt-panel/
cp "$LOGO_PATH" /usr/share/lxqt/themes/lxqt-panel/logo.png

neofetch
