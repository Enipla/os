#!/bin/bash

# Script to set up a proot Alpine environment, customize Enipla Linux, and build the ISO from Alpine Linux 3.20-stable

# Exit immediately if any command fails
set -e

# Install dependencies on Debian/Ubuntu
echo "Installing dependencies..."
sudo apt update
sudo apt install -y proot wget git xorriso curl

# Variables
OS_REPO="https://github.com/Enipla/os"  # Repository containing OS files (images, etc.)
REPO_PATH="aports"  # Path to your cloned Enipla aports repo
BRANCH="3.20-stable"
ISO_OUTPUT_DIR="/tmp/enipla-output"
ISO_NAME="enipla.iso"
CUSTOM_NAME="Enipla"
ALPINE_VERSION="3.20.3"
ALPINE_ROOT="alpine-root"
REPOSITORY_URL="http://dl-cdn.alpinelinux.org/alpine/v3.20/main"  # Specify the Alpine repository
UPDATE_KERNEL_URL="https://raw.githubusercontent.com/alpinelinux/alpine-conf/refs/heads/master/update-kernel.in"  # URL for update-kernel script

# Step 1: Download and extract Alpine miniroot filesystem
if [ ! -d "$ALPINE_ROOT" ]; then
    echo "Setting up Alpine environment..."
    wget http://mirror.nl.leaseweb.net/alpine/v3.20/releases/x86_64/alpine-minirootfs-${ALPINE_VERSION}-x86_64.tar.gz
    mkdir -p "$ALPINE_ROOT"
    sudo tar -xzf alpine-minirootfs-${ALPINE_VERSION}-x86_64.tar.gz -C "$ALPINE_ROOT"
fi

# Step 2: Start Alpine environment with proot
echo "Entering Alpine environment with proot..."
proot -R "$ALPINE_ROOT" /bin/sh -c "
    # Inside proot Alpine environment
    apk update
    apk add alpine-sdk git bash xorriso openrc lightdm networkmanager abuild apk-tools syslinux

    # Download update-kernel script and make it executable
    echo 'Downloading update-kernel script...'
    wget -O /usr/local/bin/update-kernel $UPDATE_KERNEL_URL
    chmod +x /usr/local/bin/update-kernel

    # Clone the OS resources repository
    if [ ! -d 'os' ]; then
        echo 'Cloning Enipla OS repository...'
        git clone $OS_REPO os
    fi

    # Clone the aports repository and switch to the specified branch
    if [ ! -d '$REPO_PATH' ]; then
        echo 'Cloning Enipla aports repository...'
        git clone https://github.com/Enipla/aports.git '$REPO_PATH'
    fi
    cd '$REPO_PATH'
    git checkout $BRANCH

    # Step 3: Modify mkimage.sh to include custom branding and software packages
    MKIMAGE_SCRIPT='scripts/mkimage.sh'
    echo 'Customizing \$MKIMAGE_SCRIPT...'

    # Backup original mkimage.sh
    cp \$MKIMAGE_SCRIPT \${MKIMAGE_SCRIPT}.bak

    # Add branding and default software packages
    sed -i '/^PRETTY_NAME=/c\PRETTY_NAME=\"$CUSTOM_NAME 3.20\"' \$MKIMAGE_SCRIPT

    # Insert repository URL and software packages
    sed -i '/^apk add --no-cache/ s/\$/ xfce4 xfce4-terminal thunar firefox mousepad vlc evince ristretto file-roller networkmanager networkmanager-applet htop gparted xfce4-power-manager lightdm/' \$MKIMAGE_SCRIPT
    sed -i '/^# Default repository/ a REPOSITORIES=\"$REPOSITORY_URL\"' \$MKIMAGE_SCRIPT

    # Ensure directories exist before copying files
    mkdir -p rootfs/usr/share/pixmaps
    mkdir -p rootfs/usr/share/backgrounds
    mkdir -p rootfs/etc/lightdm
    mkdir -p rootfs/etc
    mkdir -p rootfs/boot/grub
    mkdir -p rootfs/boot/syslinux

    # Copy branding assets from the 'os' directory with checks for missing files
    if [ -f os/hd_enipla_logo_icon_transparent.png ]; then
        cp os/hd_enipla_logo_icon_transparent.png rootfs/usr/share/pixmaps/
    else
        echo 'Image hd_enipla_logo_icon_transparent.png can''t be added to /usr/share/pixmaps'
    fi

    if [ -f os/enipla_background.png ]; then
        cp os/enipla_background.png rootfs/usr/share/backgrounds/
    else
        echo 'Image enipla_background.png can''t be added to /usr/share/backgrounds'
    fi

    echo 'echo \"background=/usr/share/backgrounds/enipla_background.png\" >> /etc/lightdm/lightdm-gtk-greeter.conf' >> \$MKIMAGE_SCRIPT

    # Update OS Information (os-release)
    echo 'Updating OS information to \"Enipla\" in os-release...'
    echo 'echo \"NAME=\"$CUSTOM_NAME\"\" >> rootfs/etc/os-release' >> \$MKIMAGE_SCRIPT
    echo 'echo \"ID=enipla\" >> rootfs/etc/os-release' >> \$MKIMAGE_SCRIPT
    echo 'echo \"PRETTY_NAME=\"$CUSTOM_NAME 3.20\"\" >> rootfs/etc/os-release' >> \$MKIMAGE_SCRIPT

    # Update bootloader configuration if necessary
    echo 'Updating bootloader configurations...'
    echo 'sed -i \"s/Alpine/$CUSTOM_NAME/g\" rootfs/boot/grub/grub.cfg' >> \$MKIMAGE_SCRIPT
    echo 'sed -i \"s/Alpine/$CUSTOM_NAME/g\" rootfs/boot/syslinux/syslinux.cfg' >> \$MKIMAGE_SCRIPT

    # Step 4: Ensure LightDM and NetworkManager are enabled on boot
    echo 'Configuring LightDM and NetworkManager to start on boot...'
    echo 'rc-update add lightdm' >> \$MKIMAGE_SCRIPT
    echo 'rc-update add networkmanager' >> \$MKIMAGE_SCRIPT

    # Step 5: Run mkimage.sh with profile_extended to build the ISO
    echo 'Building the ISO...'
    mkdir -p '$ISO_OUTPUT_DIR'
    chmod +x \$MKIMAGE_SCRIPT
    ./\$MKIMAGE_SCRIPT --profile extended --repository \"$REPOSITORY_URL\" --outdir '$ISO_OUTPUT_DIR' --arch x86_64

    # Step 6: Rename and move the ISO
    ISO_FILE=\$(find \"$ISO_OUTPUT_DIR\" -name 'alpine-extended-*.iso' -print -quit)
    if [ -f \"\$ISO_FILE\" ]; then
        mv \"\$ISO_FILE\" \"$ISO_OUTPUT_DIR/$ISO_NAME\"
        echo 'ISO created at $ISO_OUTPUT_DIR/$ISO_NAME'
    else
        echo 'ISO creation failed or ISO file not found.'
    fi
"

echo "Exiting Alpine environment."
