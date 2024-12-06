#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Set key variables
OS_NAME="Enipla"
RELEASE_NAME="Bedrock"

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"

# Set the paths for the logo and background
LOGO_PATH="$SCRIPT_DIR/hd_enipla_logo_icon_transparent.png"
BACKGROUND_PATH="$SCRIPT_DIR/enipla_background.png"

# Path to first-login script
FIRST_LOGIN_SCRIPT="/etc/enipla/first-login.sh"

# --- Verify Required Files ---
if [ ! -f "$LOGO_PATH" ] || [ ! -f "$BACKGROUND_PATH" ]; then
    echo "Error: Logo or background file not found."
    exit 1
fi

# --- Determine CPU Architecture ---
ARCH=$(uname -m)
case $ARCH in
    x86_64) URL="https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.30/bedrock-linux-0.7.30-x86_64.sh" ;;
    i686) URL="https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.30/bedrock-linux-0.7.30-i386.sh" ;;
    armv7l) URL="https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.30/bedrock-linux-0.7.30-armv7l.sh" ;;
    aarch64) URL="https://github.com/bedrocklinux/bedrocklinux-userland/releases/download/0.7.30/bedrock-linux-0.7.30-aarch64.sh" ;;
    *) 
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# --- Install Bedrock Linux ---
echo "Downloading and installing Bedrock Linux..."
wget -O bedrock-installer.sh "$URL"
chmod +x bedrock-installer.sh
sh bedrock-installer.sh --hijack

# --- Branding changes ---
echo "Changing branding..."
echo "Welcome to Enipla \"Begone\" OS" > /etc/motd
sed -i "s/Debian/Enipla Begone/g" /etc/issue
sed -i "s/Debian/Enipla Begone/g" /etc/os-release
sed -i "s/NAME=\"Debian/NAME=\"Enipla Begone/g" /etc/os-release
sed -i "s/PRETTY_NAME=\"Debian/PRETTY_NAME=\"Enipla Begone/g" /etc/os-release

# Change hostname
echo "enipla" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1   enipla/g" /etc/hosts

# Update and upgrade system
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get dist-upgrade -y

# Install Core System Tools and Utilities
apt-get install -y openssh-server build-essential less unzip mtr-tiny etckeeper || { echo "Core Installation failed"; exit 1; }

# Disable snapd
echo "Package: snapd" | sudo tee /etc/apt/preferences.d/nosnap.pref
echo "Pin: release a=*" | sudo tee -a /etc/apt/preferences.d/nosnap.pref
echo "Pin-Priority: -1" | sudo tee -a /etc/apt/preferences.d/nosnap.pref

sudo apt update

# Install LXDE, LightDM and Utilities
apt-get install -y lxde lightdm lightdm-gtk-greeter xterm pcmanfm neofetch \
    feh vlc gedit flatpak || { echo "System Installation failed"; exit 1; }

# Setup flatpak/flathub
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Setup enipla directory
mkdir -p /etc/enipla/

# --- Copy logo and background to global locations ---
mkdir -p /usr/share/backgrounds /usr/share/icons
cp "$LOGO_PATH" /usr/share/icons/enipla_logo.png
cp "$BACKGROUND_PATH" /usr/share/backgrounds/enipla_background.png
chmod 644 /usr/share/icons/enipla_logo.png /usr/share/backgrounds/enipla_background.png

# Do grub background
mkdir -p /boot/grub
cp "$BACKGROUND_PATH" /boot/grub/background.png

# --- Configure LightDM ---
LIGHTDM_CONFIG="/etc/lightdm/lightdm-gtk-greeter.conf"
[ ! -f "$LIGHTDM_CONFIG" ] && echo "[greeter]" > "$LIGHTDM_CONFIG"
sed -i "s|background=.*|background=/usr/share/backgrounds/enipla_background.png|g" "$LIGHTDM_CONFIG"

# --- Configure LXDE ---
mkdir -p /etc/skel/.config/lxsession/LXDE

cat > /etc/skel/.config/lxsession/LXDE/autostart <<EOL
@feh --bg-scale /usr/share/backgrounds/enipla_background.png
EOL

# --- Add Neofetch to .bashrc ---
if ! grep -q "$FIRST_LOGIN_SCRIPT" /etc/skel/.bashrc; then
    echo "neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6" >> /etc/skel/.bashrc
    echo "echo 'Welcome to $OS_NAME \"$RELEASE_NAME\"'" >> /etc/skel/.bashrc
fi

# Cleanup
echo "Echo cleaning up..."
rm bedrock-installer.sh || { echo "Cleanup failed"; }

# --- Done ---
neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6
echo "Enipla Ready!"
