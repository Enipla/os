#!/bin/bash

# Set variables for customization
DISTRO_NAME="Enipla"
ISO_OUTPUT="enipla_custom.iso"
CHROOT_DIR="./chroot"
FLATPAK_APPS=("com.brave.Browser") # Add more app IDs as needed
BRANDING_IMAGES=("enipla_background.png" "enipla_logo_brand.png" "enipla_logo_brand_transparent.png" "enipla_logo_icon.png" "enipla_logo_icon_transparent.png")

# Step 0: Install all required packages
echo "Installing required packages..."
sudo apt update
sudo apt install -y debootstrap grub-pc-bin grub-common grub2-common xorriso mtools squashfs-tools chroot lightdm enlightenment flatpak neofetch

# Step 1: Setup working directories
mkdir -p "$CHROOT_DIR"

# Step 2: Bootstrap a minimal Debian system
debootstrap --arch=amd64 stable "$CHROOT_DIR" http://deb.debian.org/debian/

# Step 3: Chroot into environment to customize it
mount --bind /dev "$CHROOT_DIR/dev"
mount --bind /proc "$CHROOT_DIR/proc"
mount --bind /sys "$CHROOT_DIR/sys"

# Copy necessary files to chroot for branding (you should replace paths as appropriate)
cp ${BRANDING_IMAGES[@]} "$CHROOT_DIR/etc/skel/"

# Enter chroot
chroot "$CHROOT_DIR" /bin/bash <<EOF

# Basic setup inside chroot
export DEBIAN_FRONTEND=noninteractive
apt update
apt upgrade -y

# Install Enlightenment Desktop Environment, flatpak, neofetch, and other essentials
apt install -y enlightenment flatpak neofetch grub-pc xorg xserver-xorg lightdm

# Configure LightDM (you can set this up to autologin if needed)
echo "[Seat:*]
autologin-user=$(whoami)" >> /etc/lightdm/lightdm.conf

# Set up Flatpak and add Flathub repo
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Install specified Flatpak applications
for app in ${FLATPAK_APPS[@]}; do
    flatpak install -y flathub \$app
done

# Set branding images as default background, logo, etc.
cp /etc/skel/enipla_background.png /usr/share/backgrounds/default_background.png
cp /etc/skel/enipla_logo_icon.png /usr/share/pixmaps/debian-logo.png

# Install any additional configurations for Enlightenment here

# Clean up
apt clean
rm -rf /tmp/* /var/tmp/*

EOF

# Exit chroot and unmount
umount -lf "$CHROOT_DIR/dev"
umount -lf "$CHROOT_DIR/proc"
umount -lf "$CHROOT_DIR/sys"

# Step 4: Generate the ISO
mkdir -p iso/boot/grub
grub-mkrescue -o "$ISO_OUTPUT" iso

echo "ISO created: $ISO_OUTPUT"
