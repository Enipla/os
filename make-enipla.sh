#!/bin/bash

# Check for root privileges
if [[ $EUID -eq 0 ]]; then
   echo "This script should not be run as root." 
   exit 1
fi

# Set variables for customization
DISTRO_NAME="Enipla"
ISO_OUTPUT="enipla_custom.iso"
CHROOT_DIR="./chroot"
FLATPAK_APPS=("com.brave.Browser") # Add more app IDs as needed
BRANDING_IMAGES=("enipla_background.png" "enipla_logo_brand.png" "enipla_logo_brand_transparent.png" "enipla_logo_icon.png" "enipla_logo_icon_transparent.png")

# Step 0: Install all required packages, including proot for non-root chroot-like environment
echo "Installing required packages..."
sudo apt update
sudo apt install -y proot debootstrap grub-pc-bin grub-common grub2-common xorriso mtools squashfs-tools lightdm enlightenment flatpak neofetch

# Step 1: Setup working directories
mkdir -p "$CHROOT_DIR"

# Step 2: Bootstrap a minimal Debian system
debootstrap --arch=amd64 stable "$CHROOT_DIR" http://deb.debian.org/debian/

# Step 3: Use proot to enter environment and customize
# Copy necessary files for branding
mkdir -p "$CHROOT_DIR/etc/skel"
cp ${BRANDING_IMAGES[@]} "$CHROOT_DIR/etc/skel/"

# Enter proot environment for customization
proot -R "$CHROOT_DIR" /bin/bash <<EOF

# Basic setup inside proot environment
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

# Clean up
apt clean
rm -rf /tmp/* /var/tmp/*

EOF

# Step 4: Generate the ISO
mkdir -p iso/boot/grub
grub-mkrescue -o "$ISO_OUTPUT" iso

echo "ISO created: $ISO_OUTPUT"
