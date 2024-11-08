#!/bin/bash

# Script to set up and build Enipla Linux from Alpine Linux 3.20-stable

# Exit if any command fails
set -e

# Variables
REPO_URL="https://github.com/Enipla/aports.git"
BRANCH="3.20-stable"
ISO_OUTPUT_DIR="/tmp/enipla-output"
ISO_NAME="enipla.iso"
LOGO_PATH="./enipla_logo_brand.png"
BACKGROUND_PATH="./enipla_background.png"
ICON_PATH="./enipla_logo_icon.png"
ICON_TRANSPARENT_PATH="./enipla_logo_icon_transparent.png"
HD_LOGO_PATH="./hd_enipla_logo_brand.png"
HD_LOGO_TRANSPARENT_PATH="./hd_enipla_logo_brand_transparent.png"
HD_ICON_PATH="./hd_enipla_logo_icon.png"
HD_ICON_TRANSPARENT_PATH="./hd_enipla_logo_icon_transparent.png"
CUSTOM_NAME="Enipla"

# Clone the repository
echo "Cloning Enipla repository... (Enipla/aports)"
git clone $REPO_URL
cd aports

# Checkout the 3.20-stable branch
echo "Switching to branch $BRANCH..."
git checkout $BRANCH

# Update OS Name in os-release
echo "Updating OS name in os-release..."
echo "NAME=\"$CUSTOM_NAME\"" | sudo tee /etc/os-release
echo "PRETTY_NAME=\"$CUSTOM_NAME 3.20\"" | sudo tee -a /etc/os-release

# Add Default Software Packages
echo "Adding default software packages..."
DEFAULT_PACKAGES="xfce4 xfce4-terminal thunar firefox mousepad vlc evince \
    ristretto file-roller networkmanager networkmanager-applet htop gparted \
    xfce4-power-manager lightdm"

# Installing packages to the ISO build configuration
sudo apk update
sudo apk add $DEFAULT_PACKAGES

# Branding Customizations
# 1. Change Login Logo and Icons
echo "Setting custom logos and icons..."
sudo cp "$LOGO_PATH" /usr/share/pixmaps/enipla_logo_brand.png
sudo cp "$ICON_PATH" /usr/share/icons/enipla_logo_icon.png
sudo cp "$ICON_TRANSPARENT_PATH" /usr/share/icons/enipla_logo_icon_transparent.png
sudo cp "$HD_LOGO_PATH" /usr/share/pixmaps/hd_enipla_logo_brand.png
sudo cp "$HD_LOGO_TRANSPARENT_PATH" /usr/share/pixmaps/hd_enipla_logo_brand_transparent.png
sudo cp "$HD_ICON_PATH" /usr/share/icons/hd_enipla_logo_icon.png
sudo cp "$HD_ICON_TRANSPARENT_PATH" /usr/share/icons/hd_enipla_logo_icon_transparent.png

# Update LightDM or other login managers to use the new background
LIGHTDM_CONF="/etc/lightdm/lightdm-gtk-greeter.conf"
if [ -f "$LIGHTDM_CONF" ]; then
    echo "Setting LightDM background..."
    sudo sed -i "s|#background=.*|background=$BACKGROUND_PATH|" "$LIGHTDM_CONF"
fi

# 2. Set Custom Desktop Background
echo "Setting custom desktop background..."
sudo mkdir -p /usr/share/backgrounds
sudo cp "$BACKGROUND_PATH" /usr/share/backgrounds/enipla_background.png
# Configure XFCE to use the custom background by default
XFCE_DESKTOP_CONF="/usr/share/xfce4/backdrops/default.png"
sudo ln -sf /usr/share/backgrounds/enipla_background.png "$XFCE_DESKTOP_CONF"

# Ensure services start at boot
echo "Configuring services to start on boot..."
sudo rc-update add lightdm
sudo rc-update add NetworkManager

# Build the ISO
echo "Building the ISO..."
mkdir -p $ISO_OUTPUT_DIR
./scripts/mkimage.sh --profile standard --outdir $ISO_OUTPUT_DIR --arch x86_64

# Rename and move the ISO
ISO_PATH="$ISO_OUTPUT_DIR/$ISO_NAME"
mv "$ISO_OUTPUT_DIR/alpine-standard-*.iso" "$ISO_PATH"

echo "ISO created at $ISO_PATH"
echo "Enipla build complete!"
