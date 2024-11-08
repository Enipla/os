#!/bin/bash

# Script to customize and build Enipla Linux ISO from Alpine Linux 3.20-stable

# Exit immediately if any command fails
set -e

# Variables
REPO_PATH="aports"  # Path to your cloned Enipla aports repo
BRANCH="3.20-stable"
ISO_OUTPUT_DIR="/tmp/enipla-output"
ISO_NAME="enipla.iso"
LOGO_PATH="./hd_enipla_logo_icon_transparent.png"
BACKGROUND_PATH="./enipla_background.png"
CUSTOM_NAME="Enipla"

# Step 1: Clone the repository and switch to the 3.20-stable branch if not already cloned
if [ ! -d "$REPO_PATH" ]; then
    echo "Cloning Enipla repository..."
    git clone https://github.com/Enipla/aports.git "$REPO_PATH"
fi
cd "$REPO_PATH"
git checkout $BRANCH

# Step 2: Modify mkimage.sh to include custom branding and software packages
MKIMAGE_SCRIPT="scripts/mkimage.sh"
echo "Customizing $MKIMAGE_SCRIPT..."

# Backup original mkimage.sh
cp "$MKIMAGE_SCRIPT" "$MKIMAGE_SCRIPT.bak"

# Add branding and default software packages
sed -i "/^PRETTY_NAME=/c\PRETTY_NAME=\"$CUSTOM_NAME 3.20\"" "$MKIMAGE_SCRIPT"

# Insert software packages and branding assets at an appropriate point in the script
sed -i "/^apk add --no-cache/ s/$/ xfce4 xfce4-terminal thunar firefox mousepad vlc evince ristretto file-roller networkmanager networkmanager-applet htop gparted xfce4-power-manager lightdm/" "$MKIMAGE_SCRIPT"

# Add branding assets
echo "cp $LOGO_PATH rootfs/usr/share/pixmaps/" >> "$MKIMAGE_SCRIPT"
echo "cp $BACKGROUND_PATH rootfs/usr/share/backgrounds/" >> "$MKIMAGE_SCRIPT"
echo "echo \"background=/usr/share/backgrounds/enipla_background.png\" >> /etc/lightdm/lightdm-gtk-greeter.conf" >> "$MKIMAGE_SCRIPT"

# Update OS Information (os-release)
echo "Updating OS information to 'Enipla' in os-release..."
echo "echo 'NAME=\"$CUSTOM_NAME\"' >> rootfs/etc/os-release" >> "$MKIMAGE_SCRIPT"
echo "echo 'ID=enipla' >> rootfs/etc/os-release" >> "$MKIMAGE_SCRIPT"
echo "echo 'PRETTY_NAME=\"$CUSTOM_NAME 3.20\"' >> rootfs/etc/os-release" >> "$MKIMAGE_SCRIPT"

# Update bootloader configuration if necessary
echo "Updating bootloader configurations..."
echo "sed -i 's/Alpine/$CUSTOM_NAME/g' rootfs/boot/grub/grub.cfg" >> "$MKIMAGE_SCRIPT"
echo "sed -i 's/Alpine/$CUSTOM_NAME/g' rootfs/boot/syslinux/syslinux.cfg" >> "$MKIMAGE_SCRIPT"

# Step 3: Ensure LightDM and NetworkManager are enabled on boot
echo "Configuring LightDM and NetworkManager to start on boot..."
echo "rc-update add lightdm" >> "$MKIMAGE_SCRIPT"
echo "rc-update add NetworkManager" >> "$MKIMAGE_SCRIPT"

# Step 4: Run mkimage.sh to build the ISO
echo "Building the ISO..."
mkdir -p "$ISO_OUTPUT_DIR"
chmod +x "$MKIMAGE_SCRIPT"
./"$MKIMAGE_SCRIPT" --profile standard --outdir "$ISO_OUTPUT_DIR" --arch x86_64

# Step 5: Rename and move the ISO
ISO_PATH="$ISO_OUTPUT_DIR/$ISO_NAME"
mv "$ISO_OUTPUT_DIR/alpine-standard-*.iso" "$ISO_PATH"

echo "ISO created at $ISO_PATH"
echo "Enipla build complete!"
