#!/bin/bash

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root. Please use sudo."
   exit 1
fi

# Set up directories
BUILD_DIR="enipla-live"
ISO_NAME="enipla_custom.iso"
BRANDING_IMAGES=("enipla_background.png" "hd_enipla_logo_brand_transparent.png")

# Install necessary packages
echo "Installing required packages..."
apt update
apt install -y live-build curl plymouth-themes

# Create and navigate to the build directory
mkdir -p "$BUILD_DIR"
cd "$BUILD_DIR"

# Configure Debian Live Build with the required packages
echo "Configuring Debian Live Build..."
lb config --architecture amd64 \
          --distribution stable \
          --debian-installer live \
          --archive-areas "main contrib non-free" \
          --packages "enlightenment flatpak neofetch lightdm xorg grub-pc plymouth"

# Add branding images and LightDM autologin config
echo "Setting up branding and configurations..."

# Create directories for branding and config
mkdir -p config/includes.chroot/usr/share/backgrounds
mkdir -p config/includes.chroot/usr/share/pixmaps
mkdir -p config/includes.chroot/etc/lightdm

# Copy branding images
for img in "${BRANDING_IMAGES[@]}"; do
    if [ -f "../$img" ]; then
        cp "../$img" "config/includes.chroot/usr/share/backgrounds/default_background.png"
        cp "../$img" "config/includes.chroot/usr/share/pixmaps/debian-logo.png"
    else
        echo "Warning: Branding image $img not found in the current directory."
    fi
done

# Configure autologin for LightDM
echo "[Seat:*]
autologin-user=root" > config/includes.chroot/etc/lightdm/lightdm.conf

# Add a hook to install Flatpak and Brave Browser
echo "Creating Flatpak installation hook..."
mkdir -p config/hooks
echo "#!/bin/sh
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub com.brave.Browser" > config/hooks/flatpak.chroot
chmod +x config/hooks/flatpak.chroot

# Customizing OS release information for branding
echo "Customizing OS release information..."

# Set up OS release file
mkdir -p config/includes.chroot/etc
echo 'PRETTY_NAME="Enipla GNU/Linux"
NAME="Enipla"
VERSION="1.0 (Custom)"
ID=enipla
VERSION_ID="1.0"
HOME_URL="https://github.com/Enipla"
SUPPORT_URL="https://github.com/Enipla/issues"
BUG_REPORT_URL="https://github.com/Enipla/issues"' > config/includes.chroot/etc/os-release

# Set up issue file for branding at login
echo "Welcome to Enipla GNU/Linux 1.0" > config/includes.chroot/etc/issue

# Customizing Neofetch for Enipla branding
mkdir -p config/includes.chroot/etc/neofetch
echo 'info "OS" distro
info "Kernel" kernel
info "Uptime" uptime
info "Packages" packages
info "Shell" shell
info "Resolution" resolution
info "DE" de
info "WM" wm
info "Terminal" term
info "CPU" cpu
info "Memory" memory
title="Enipla GNU/Linux 1.0"' > config/includes.chroot/etc/neofetch/config.conf

# Customize Enlightenment Start Menu Branding (if applicable)
echo "Creating custom startup for branding..."
echo "#!/bin/sh
enlightenment_start
" > config/includes.chroot/usr/bin/enipla-start

chmod +x config/includes.chroot/usr/bin/enipla-start

# Set default session command to enipla-start
mkdir -p config/includes.chroot/etc/xdg
echo '[Desktop Entry]
Name=Enipla
Comment=Start Enipla
Exec=/usr/bin/enipla-start
Type=Application' > config/includes.chroot/etc/xdg/enipla.desktop

# Set GRUB Menu Title to "Enipla"
echo "Customizing GRUB boot menu..."
mkdir -p config/includes.chroot/etc/default
echo 'GRUB_DISTRIBUTOR="Enipla GNU/Linux"' > config/includes.chroot/etc/default/grub

# Set the hostname to "enipla"
echo "enipla" > config/includes.chroot/etc/hostname

# Set up a Plymouth boot splash (optional)
echo "Setting up Plymouth for a branded boot splash..."
mkdir -p config/includes.chroot/usr/share/plymouth/themes/enipla
cp ../$BRANDING_IMAGES[0] config/includes.chroot/usr/share/plymouth/themes/enipla/background.png
cat <<EOF > config/includes.chroot/usr/share/plymouth/themes/enipla/enipla.plymouth
[Plymouth Theme]
Name=Enipla
Description=A custom boot splash for Enipla Linux
ModuleName=script

[script]
ImageDir=/usr/share/plymouth/themes/enipla
ScriptFile=/usr/share/plymouth/themes/enipla/enipla.script
EOF

cat <<EOF > config/includes.chroot/usr/share/plymouth/themes/enipla/enipla.script
wallpaper_image = Image("background.png");
wallpaper_image.ScaleToScreen();
wallpaper_image.Show();
EOF

# Enable the Plymouth theme
echo "plymouth-theme-enipla" > config/includes.chroot/etc/plymouth/plymouthd.conf

# Build the ISO
echo "Building the ISO..."
lb build

# Rename the output ISO and move it to the parent directory
if [ -f live-image-amd64.hybrid.iso ]; then
    mv live-image-amd64.hybrid.iso "../$ISO_NAME"
    echo "ISO created successfully: ../$ISO_NAME"
else
    echo "ISO build failed."
    exit 1
fi

# Clean up
echo "Cleaning up build files..."
cd ..
rm -rf "$BUILD_DIR"

echo "Done!"
