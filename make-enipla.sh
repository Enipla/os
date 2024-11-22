#!/bin/bash

# Set key variables
OS_NAME="Enipla"
RELEASE_NAME="Begone"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Set the paths for the logo and background (relative to the script's location)
LOGO_PATH="$SCRIPT_DIR/hd_enipla_logo_icon_transparent.png"
BACKGROUND_PATH="$SCRIPT_DIR/enipla_background.png"

# --- No need to enter chroot, as the script will be executed inside it ---

# Update package lists
apt-get update

# Install LXQT, LXQT Core, and LightDM
apt-get install -y lxqt lxqt-core lightdm

# Branding changes
sed -i "s/Debian GNU\/Linux/Enipla Begone/g" /etc/issue
sed -i "s/Debian GNU\/Linux/Enipla Begone/g" /etc/os-release

# --- LightDM Configuration ---
# Set the background image
sed -i "s/#background=/background=$BACKGROUND_PATH/g" /etc/lightdm/lightdm-gtk-greeter.conf

# --- LXQT Configuration ---
# Set the logo (replace 'lxqt-panel' with your actual theme name if different)
mkdir -p /usr/share/lxqt/themes/lxqt-panel/
cp "$LOGO_PATH" /usr/share/lxqt/themes/lxqt-panel/logo.png
