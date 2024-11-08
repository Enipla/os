#!/bin/bash

# Script to set up an Alpine VM image with customizations for Enipla Linux, including a desktop environment

# Exit immediately if any command fails
set -e

# Install dependencies on Debian/Ubuntu
echo "Installing dependencies..."
sudo apt update
sudo apt install -y proot wget git xorriso curl openssl qemu-utils

# Variables
OS_REPO="https://github.com/Enipla/os"  # Repository containing OS files (images, etc.)
ISO_OUTPUT_DIR="$(pwd)/enipla-output"
ISO_NAME="enipla.iso"
CUSTOM_NAME="Enipla"
REPOSITORY_URL="http://dl-cdn.alpinelinux.org/alpine"  # Base URL for the Alpine repository
ALPINE_MAKE_VM_IMAGE_URL="https://raw.githubusercontent.com/alpinelinux/alpine-make-vm-image/refs/heads/master/alpine-make-vm-image"

# Generate signing keys
echo "Generating signing keys..."
openssl req -new -x509 -days 3650 -nodes -out enipla-cert.pem -keyout enipla-key.pem -subj "/CN=Enipla Kernel Signing"

# Download alpine-make-vm-image tool
if [ ! -f "alpine-make-vm-image" ]; then
    echo "Downloading alpine-make-vm-image..."
    wget -O alpine-make-vm-image $ALPINE_MAKE_VM_IMAGE_URL
    chmod +x alpine-make-vm-image
fi

# Clone the OS resources repository
if [ ! -d 'os' ]; then
    echo 'Cloning Enipla OS repository...'
    git clone $OS_REPO os
fi

# Define a customization script for Enipla Linux
cat << 'EOF' > enipla-customize.sh
#!/bin/sh

# Add XFCE desktop environment, network management tools, and additional utilities
apk add --no-cache xfce4 xfce4-terminal thunar firefox mousepad vlc evince ristretto file-roller networkmanager networkmanager-applet htop gparted xfce4-power-manager lightdm lightdm-gtk-greeter dbus

# Enable necessary services
rc-update add dbus
rc-update add lightdm
rc-update add NetworkManager

# Set custom branding
echo "Setting custom branding for Enipla..."
echo "PRETTY_NAME=\"$CUSTOM_NAME 3.20\"" > /etc/os-release
echo "NAME=\"$CUSTOM_NAME\"" >> /etc/os-release
echo "ID=enipla" >> /etc/os-release

# Copy branding assets
echo "Copying Enipla branding assets..."
mkdir -p /usr/share/pixmaps /usr/share/backgrounds /etc/lightdm

# Copy background and logo if available
if [ -f /mnt/data/os/enipla_background.png ]; then
    cp /mnt/data/os/enipla_background.png /usr/share/backgrounds/enipla_background.png
else
    echo "Background image not found."
fi

if [ -f /mnt/data/os/hd_enipla_logo_icon_transparent.png ]; then
    cp /mnt/data/os/hd_enipla_logo_icon_transparent.png /usr/share/pixmaps/enipla_logo.png
else
    echo "Logo image not found."
fi

# Update lightdm configuration for background
if [ -f /etc/lightdm/lightdm-gtk-greeter.conf ]; then
    echo "background=/usr/share/backgrounds/enipla_background.png" >> /etc/lightdm/lightdm-gtk-greeter.conf
fi
EOF

# Make the customization script executable
chmod +x enipla-customize.sh

# Run alpine-make-vm-image to create the Enipla image with GUI
./alpine-make-vm-image \
    -m "$REPOSITORY_URL" \
    -b "v3.20" \
    -s 2G \
    -f raw \
    -p "alpine-base openrc" \
    -a x86_64 \
    "$ISO_OUTPUT_DIR/$ISO_NAME" \
    ./enipla-customize.sh

# Clean up
rm enipla-customize.sh

echo "ISO created at $ISO_OUTPUT_DIR/$ISO_NAME"
