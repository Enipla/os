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

# --- Verify Required Files ---
if [ ! -f "$LOGO_PATH" ] || [ ! -f "$BACKGROUND_PATH" ]; then
    echo "Error: Logo or background file not found."
    exit 1
fi

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
apt-get install -y openssh-server build-essential less unzip mtr-tiny etckeeper curl wget git || { echo "Core Installation failed"; exit 1; }

# Disable snapd
echo "Package: snapd" | sudo tee /etc/apt/preferences.d/nosnap.pref
echo "Pin: release a=*" | sudo tee -a /etc/apt/preferences.d/nosnap.pref
echo "Pin-Priority: -1" | sudo tee -a /etc/apt/preferences.d/nosnap.pref

sudo apt update

# Install LXQt, LightDM, and Utilities
apt-get install -y lxqt lightdm lightdm-gtk-greeter qterminal pcmanfm-qt neofetch \
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

# --- Configure LightDM ---
LIGHTDM_CONFIG="/etc/lightdm/lightdm-gtk-greeter.conf"
[ ! -f "$LIGHTDM_CONFIG" ] && echo "[greeter]" > "$LIGHTDM_CONFIG"
sed -i "s|background=.*|background=/usr/share/backgrounds/enipla_background.png|g" "$LIGHTDM_CONFIG"

# --- Configure LXQt ---
mkdir -p /etc/skel/.config/lxqt

cat > /etc/skel/.config/lxqt/session.conf <<EOL
[General]
lastConfiguredDesktop=/usr/share/backgrounds/enipla_background.png
theme=default
EOL

# --- Set Default Applications ---
cat >> /etc/skel/.config/lxqt/session.conf <<EOL
[Default Applications]
filemanager=pcmanfm-qt
terminal=qterminal
webbrowser=brave
EOL

# --- Add Neofetch to .bashrc ---
if ! grep -q "neofetch" /etc/skel/.bashrc; then
    echo "neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6" >> /etc/skel/.bashrc
    echo "echo 'Welcome to $OS_NAME \"$RELEASE_NAME\"'" >> /etc/skel/.bashrc
fi

# --- Configure Boot Splash ---
apt-get install -y plymouth plymouth-themes || { echo "Plymouth installation failed"; }
mkdir -p /usr/share/plymouth/themes/enipla
cat > /usr/share/plymouth/themes/enipla/enipla.plymouth <<EOL
[Plymouth Theme]
Name=Enipla
Description=Custom boot splash for Enipla
ModuleName=script
EOL
cat > /usr/share/plymouth/themes/enipla/enipla.script <<EOL
Window.SetBackgroundTopColor (0.15, 0.15, 0.15);
Window.SetBackgroundBottomColor (0.10, 0.10, 0.10);
Image.Add (0, 0, "/usr/share/icons/enipla_logo.png");
EOL
plymouth-set-default-theme enipla -R

# --- Configure GRUB Menu ---
apt install grub-common -y || { echo "Grub common installation failed"; }

mkdir -p /boot/grub/themes/enipla
cat > /boot/grub/themes/enipla/theme.txt <<EOL
title-font: "DejaVuSans-Bold"
title-color: "#FFFFFF"
desktop-image: "/usr/share/backgrounds/enipla_background.png"
EOL
sed -i "s|^#*GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/enipla/theme.txt|g" /etc/default/grub
if command -v update-grub &> /dev/null; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- Done ---
neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6
echo "Enipla Ready!"
