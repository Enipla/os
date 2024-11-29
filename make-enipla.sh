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

# Path to first-login script
FIRST_LOGIN_SCRIPT="/etc/enipla/first-login.sh"

# --- Verify Required Files ---
if [ ! -f "$LOGO_PATH" ] || [ ! -f "$BACKGROUND_PATH" ]; then
    echo "Error: Logo or background file not found."
    exit 1
fi

# --- Branding changes ---
echo "Welcome to Enipla \"Begone\" OS" > /etc/motd
sed -i "s/Ubuntu/Enipla Begone/g" /etc/issue
sed -i "s/Ubuntu/Enipla Begone/g" /etc/os-release
sed -i "s/NAME=\"Ubuntu/NAME=\"Enipla Begone/g" /etc/os-release
sed -i "s/PRETTY_NAME=\"Ubuntu/PRETTY_NAME=\"Enipla Begone/g" /etc/os-release

# Change hostname
echo "enipla" > /etc/hostname
sed -i "s/127.0.1.1.*/127.0.1.1   enipla/g" /etc/hosts

# Update and upgrade system
export DEBIAN_FRONTEND=noninteractive
apt-get update && apt-get dist-upgrade -y

# Install Core System Tools and Utilities
apt-get install -y openssh-server sudo screen iproute resolvconf \
    build-essential tcpdump vlan mii-diag firehol apticron atsar ethtool \
    denyhosts rdist bzip2 xclip etckeeper git-core less unzip mtr-tiny curl \
    gdebi-core xbase-clients rsync psmisc iperf lshw wget pastebinit nmap scapy \
    vim nano

# Install Openbox, LightDM and Utilities
apt-get install -y openbox lightdm lightdm-gtk-greeter xterm pcmanfm tint2 neofetch \
    feh xcompmgr firefox-esr vlc gedit

# --- Copy logo and background to global locations ---
mkdir -p /usr/share/backgrounds /usr/share/icons
cp "$LOGO_PATH" /usr/share/icons/enipla_logo.png
cp "$BACKGROUND_PATH" /usr/share/backgrounds/enipla_background.png
chmod 644 /usr/share/icons/enipla_logo.png /usr/share/backgrounds/enipla_background.png

# --- Configure LightDM ---
LIGHTDM_CONFIG="/etc/lightdm/lightdm-gtk-greeter.conf"
[ ! -f "$LIGHTDM_CONFIG" ] && echo "[greeter]" > "$LIGHTDM_CONFIG"
sed -i "s|background=.*|background=/usr/share/backgrounds/enipla_background.png|g" "$LIGHTDM_CONFIG"

# --- Configure Openbox ---
mkdir -p /etc/skel/.config/openbox
cat > /etc/skel/.config/openbox/autostart <<EOL
feh --bg-scale "/usr/share/backgrounds/enipla_background.png" &
tint2 &
pcmanfm --desktop &
EOL

mkdir -p /etc/skel/.themes/enipla
ln -sf /usr/share/icons/enipla_logo.png /etc/skel/.themes/enipla/logo.png

# --- Add Neofetch to .bashrc ---
if ! grep -q "$FIRST_LOGIN_SCRIPT" /etc/skel/.bashrc; then
    echo "neofetch --ascii_distro Ubuntu --config off --ascii_colors 2 4 6" >> /etc/skel/.bashrc
    echo "echo 'Welcome to $OS_NAME \"$RELEASE_NAME\"'" >> /etc/skel/.bashrc
fi

# --- First-Login Script Setup ---
mkdir -p /etc/enipla/
cat > "$FIRST_LOGIN_SCRIPT" <<'EOF'
#!/bin/bash
apt-get update
apt-get install -y flatpak abiword gnumeric sylpheed zathura mpv xmms mtpaint gftp \
    leafpad zzzfm peazip
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --noninteractive -y flathub com.brave.Browser app.drey.Warp \
    org.kde.isoimagewriter com.valvesoftware.Steam
apt-get upgrade -y
apt-get autoremove -y
rm -- "$0"
EOF
chmod +x "$FIRST_LOGIN_SCRIPT"
echo "$FIRST_LOGIN_SCRIPT" >> /etc/skel/.bashrc
