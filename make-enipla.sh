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
apt-get install -y lximage-qt lxqt-sudo lxqt-about lxqt-theme || { echo "LXQt tools/packages installation failed"; exit 1; }

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
apt install grub-common -y || { echo "Grub common installation failed"; }
mkdir -p /boot/grub/themes/enipla
cat > /boot/grub/themes/enipla/theme.txt <<EOL
title-font: "DejaVuSans-Bold"
title-color: "#FFFFFF"
desktop-image: "/usr/share/backgrounds/enipla_background.png"
EOL
sed -i "s|^#*GRUB_THEME=.*|GRUB_THEME=/boot/grub/themes/enipla/theme.txt|g" /etc/default/grub
sed -i "s|^#*GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"quiet splash\"|g" /etc/default/grub
if command -v update-grub &> /dev/null; then
    update-grub
else
    grub-mkconfig -o /boot/grub/grub.cfg
fi

# --- Cleanup ---
echo "Cleaning up..."
apt-get autoremove -y
apt-get clean
rm -rf /var/lib/apt/lists/*

# --- Done ---
neofetch --ascii_distro Bedrock --config off --ascii_colors 2 4 6
echo "Enipla Ready!"
