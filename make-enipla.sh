#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root."
    exit 1
fi

# Set key variables
OS_NAME="Enipla"
RELEASE_NAME="Begone"

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

# Add Brave browser
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list

sudo apt update

# Install LXQt, LightDM, and Utilities
apt-get install -y lxqt lightdm lightdm-gtk-greeter qterminal pcmanfm-qt neofetch \
    feh vlc gedit flatpak brave-browser || { echo "System Installation failed"; exit 1; }

# LXQt extras
apt-get install -y lximage-qt lxqt-sudo lxqt-about lxqt-themes || { echo "LXQt tools/packages installation failed"; exit 1; }

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
theme=frost
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

# --- Configure Plymouth Theme ---
echo "Setting up plymouth..."

apt-get install -y plymouth plymouth-themes || { echo "Plymouth installation failed"; }
mkdir -p /usr/share/plymouth/themes/enipla

# Define Plymouth theme configuration
cat > /usr/share/plymouth/themes/enipla/enipla.plymouth <<EOL
[Plymouth Theme]
Name=Enipla
Description=EniplaOS
ModuleName=script
EOL

# Define Plymouth animation script
cat > /usr/share/plymouth/themes/enipla/enipla.script <<EOL
Window.SetBackgroundTopColor (0, 0, 0);
Window.SetBackgroundBottomColor (0, 0, 0);

logo = Image.Add (0.5, 0.5, "/usr/share/icons/enipla_logo.png");
Image.SetAnchorPoint (logo, 0.5, 0.5);

scale = 1.0;
scaleDirection = 1;

title = Text.Add (0.5, 0.1, "", 0.05);
Text.SetAnchorPoint (title, 0.5, 0.5);
Text.SetColor (title, 1, 1, 1);

subtitle = Text.Add (0.5, 0.2, "", 0.03);
Text.SetAnchorPoint (subtitle, 0.5, 0.5);
Text.SetColor (subtitle, 0.8, 0.8, 0.8);

dots = Text.Add (0.5, 0.85, ".", 0.03);
Text.SetAnchorPoint (dots, 0.5, 0.5);
Text.SetColor (dots, 1, 1, 1);

operation = Splash.GetOperation ();  # Get the current Plymouth operation

# Set messages based on the current operation
if operation == "boot-up" then
   Text.SetText (title, "Welcome to Enipla");
   Text.SetText (subtitle, "Booting up...");
elseif operation == "shutdown" then
   Text.SetText (title, "Goodbye!");
   Text.SetText (subtitle, "Shutting down...");
elseif operation == "reboot" then
   Text.SetText (title, "See you soon!");
   Text.SetText (subtitle, "Rebooting...");
elseif operation == "updates" then
   Text.SetText (title, "Installing Updates...");
   Text.SetText (subtitle, "Do not turn off your computer.");
elseif operation == "system-upgrade" then
   Text.SetText (title, "Upgrading System...");
   Text.SetText (subtitle, "Do not turn off your computer.");
elseif operation == "firmware-upgrade" then
   Text.SetText (title, "Upgrading Firmware...");
   Text.SetText (subtitle, "Do not turn off your computer.");
else
   Text.SetText (title, "Enipla OS");
   Text.SetText (subtitle, "Processing...");
end

dotState = 0;

# Animation loop
while true
   # Pulsating logo
   scale = scale + (scaleDirection * 0.005);
   if scale >= 1.1 then
      scaleDirection = -1;
   elseif scale <= 0.9 then
      scaleDirection = 1;
   end
   Image.SetScale (logo, scale, scale);

   # Animated dots
   dotState = dotState + 1;
   if dotState > 3 then
      dotState = 1;
   end
   if dotState == 1 then
      Text.SetText (dots, ".");
   elseif dotState == 2 then
      Text.SetText (dots, "..");
   elseif dotState == 3 then
      Text.SetText (dots, "...");
   end

   Window.Draw ();
   Sleep (0.48);
end
EOL


plymouth-set-default-theme enipla -R

# --- Configure GRUB Menu ---
apt-get install -y grub-common || { echo "Grub installation failed"; exit 1; }

# Prepare GRUB configuration directory
echo "Setting up GRUB..."

mkdir -p /boot/efi

# Copy theme assets
if [ -f "$BACKGROUND_PATH" ]; then
    cp "$BACKGROUND_PATH" /boot/grub/themes/enipla/background.png
fi

# Create the GRUB configuration file
GRUB_DIR="/boot/grub"
EFI_DIR="/boot/efi/EFI/BOOT"
KERNEL_PATH="/boot/vmlinuz"
INITRD_PATH="/boot/initrd.img"
DISK_PART="(hd0,1)"
ROOT_PART="/dev/sda1"

# Create GRUB configuration
echo "Creating GRUB configuration..."
mkdir -p $GRUB_DIR
cat > $GRUB_DIR/grub.cfg <<EOL
set default=0
set timeout=5

background_image /boot/grub/themes/enipla/background.png

menuentry "Enipla OS" {
    set root=$DISK_PART
    linux $KERNEL_PATH root=$ROOT_PART quiet splash
    initrd $INITRD_PATH
}

menuentry "Enipla OS (Recovery Mode)" {
    set root=$DISK_PART
    linux $KERNEL_PATH root=$ROOT_PART single
    initrd $INITRD_PATH
}
EOL

# BIOS GRUB setup
echo "Setting up GRUB for BIOS..."
mkdir -p $GRUB_DIR/i386-pc
cp /usr/lib/grub/i386-pc/* $GRUB_DIR/i386-pc/

# UEFI GRUB setup
echo "Setting up GRUB for UEFI..."
mkdir -p $EFI_DIR
cp /usr/lib/grub/x86_64-efi/* $EFI_DIR/
cp /usr/lib/shim/shimx64.efi $EFI_DIR/bootx64.efi

echo "GRUB setup complete."

# --- Cleanup Apt Cache ---
echo "Cleaning up apt cache..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- Done ---
neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6
echo "Enipla Ready!"
