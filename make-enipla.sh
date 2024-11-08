#!/bin/bash

# Script to customize and build Enipla Linux ISO from Alpine Linux 3.20-stable
# with a temporary Alpine chroot environment on Debian/Ubuntu

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
ALPINE_CHROOT="/alpine-chroot"

# Step 0: Download and set up the Alpine root filesystem for chroot
if [ ! -d "$ALPINE_CHROOT" ]; then
    echo "Setting up Alpine chroot environment..."
    wget -q http://dl-cdn.alpinelinux.org/alpine/v3.20/releases/x86_64/alpine-minirootfs-3.20.3-x86_64.tar.gz
    sudo mkdir -p "$ALPINE_CHROOT"
    sudo tar -xzf alpine-minirootfs-3.20.3-x86_64.tar.gz -C "$ALPINE_CHROOT"
    rm alpine-minirootfs-3.20.3-x86_64.tar.gz
fi

# Mount necessary filesystems for chroot
sudo mount -t proc /proc "$ALPINE_CHROOT/proc"
sudo mount --rbind /sys "$ALPINE_CHROOT/sys"
sudo mount --make-rslave "$ALPINE_CHROOT/sys"
sudo mount --rbind /dev "$ALPINE_CHROOT/dev"
sudo mount --make-rslave "$ALPINE_CHROOT/dev"

# Step 1: Enter the chroot and set up environment
sudo chroot "$ALPINE_CHROOT" /bin/sh <<EOF

# Update APK repositories and install build tools
apk update
apk add alpine-sdk

# Step 2: Clone the repository and switch to the 3.20-stable branch if not already cloned
if [ ! -d "$REPO_PATH" ]; then
    echo "Cloning Enipla repository..."
    git clone https://github.com/Enipla/aports.git "$REPO_PATH"
fi
cd "$REPO_PATH"
git checkout $BRANCH

# Modify mkimage.sh to include custom branding and software packages
MKIMAGE_SCRIPT="scripts/mkimage.sh"
echo "Customizing \$MKIMAGE_SCRIPT..."

# Backup original mkimage.sh
cp "\$MKIMAGE_SCRIPT" "\$MKIMAGE_SCRIPT.bak"

# Add branding and default software packages
sed -i "/^PRETTY_NAME=/c\PRETTY_NAME=\"$CUSTOM_NAME 3.20\"" "\$MKIMAGE_SCRIPT"

# Insert software packages and branding assets at an appropriate point in the script
sed -i "/^apk add --no-cache/ s/\$/ xfce4 xfce4-terminal thunar firefox mousepad vlc evince ristretto file-roller networkmanager networkmanager-applet htop gparted xfce4-power-manager lightdm/" "\$MKIMAGE_SCRIPT"

# Add branding assets
echo "cp $LOGO_PATH rootfs/usr/share/pixmaps/" >> "\$MKIMAGE_SCRIPT"
echo "cp $BACKGROUND_PATH rootfs/usr/share/backgrounds/" >> "\$MKIMAGE_SCRIPT"
echo "echo \"background=/usr/share/backgrounds/enipla_background.png\" >> /etc/lightdm/lightdm-gtk-greeter.conf" >> "\$MKIMAGE_SCRIPT"

# Update OS Information (os-release)
echo "Updating OS information to 'Enipla' in os-release..."
echo "echo 'NAME=\"$CUSTOM_NAME\"' >> rootfs/etc/os-release" >> "\$MKIMAGE_SCRIPT"
echo "echo 'ID=enipla' >> rootfs/etc/os-release" >> "\$MKIMAGE_SCRIPT"
echo "echo 'PRETTY_NAME=\"$CUSTOM_NAME 3.20\"' >> rootfs/etc/os-release" >> "\$MKIMAGE_SCRIPT"

# Update bootloader configuration if necessary
echo "Updating bootloader configurations..."
echo "sed -i 's/Alpine/$CUSTOM_NAME/g' rootfs/boot/grub/grub.cfg" >> "\$MKIMAGE_SCRIPT"
echo "sed -i 's/Alpine/$CUSTOM_NAME/g' rootfs/boot/syslinux/syslinux.cfg" >> "\$MKIMAGE_SCRIPT"

# Ensure LightDM and NetworkManager are enabled on boot
echo "Configuring LightDM and NetworkManager to start on boot..."
echo "rc-update add lightdm" >> "\$MKIMAGE_SCRIPT"
echo "rc-update add NetworkManager" >> "\$MKIMAGE_SCRIPT"

# Step 3: Run mkimage.sh to build the ISO
echo "Building the ISO..."
mkdir -p "$ISO_OUTPUT_DIR"
chmod +x "\$MKIMAGE_SCRIPT"
./"\$MKIMAGE_SCRIPT" --profile standard --outdir "$ISO_OUTPUT_DIR" --arch x86_64

EOF

# Step 4: Rename and move the ISO
ISO_PATH="$ISO_OUTPUT_DIR/$ISO_NAME"
sudo mv "$ISO_OUTPUT_DIR/alpine-standard-*.iso" "$ISO_PATH"

# Clean up and unmount the chroot environment
sudo umount -R "$ALPINE_CHROOT/proc"
sudo umount -R "$ALPINE_CHROOT/sys"
sudo umount -R "$ALPINE_CHROOT/dev"

echo "ISO created at $ISO_PATH"
echo "Enipla build complete!"
