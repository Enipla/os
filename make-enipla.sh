#!/bin/bash

# Define variables
ISO_DIR="/media/cubic/iso"  # Adjust if your ISO mount point is different
WORK_DIR="/media/cubic/chroot"  # Adjust if your chroot environment is different
GITHUB_REPO="https://github.com/Enipla/os"

# 1. Mount the ISO
sudo mount -o loop "${ISO_DIR}/debian.iso" "${WORK_DIR}"

# 2. Update OS name and release
sudo sed -i 's/Debian GNU\/Linux/Enipla/g' "${WORK_DIR}/etc/os-release"
sudo sed -i 's/bullseye/Begone/g' "${WORK_DIR}/etc/os-release"

# 3. Change installer name (this may vary depending on the installer used)
# Example for GRUB:
sudo sed -i 's/Debian GNU\/Linux/Enipla Begone/g' "${WORK_DIR}/boot/grub/grub.cfg"

# 4. Download logo and background
cd "${WORK_DIR}/usr/share/backgrounds/"
sudo git clone "${GITHUB_REPO}"
sudo mv os/hd_enipla_logo_icon_transparent.png enipla_logo.png
sudo mv os/enipla_background.png .
sudo rm -rf os

# 5. Set logo and background (this will depend on your display manager)
# Example for LightDM:
sudo sed -i 's/#background=/background=\/usr\/share\/backgrounds\/enipla_background.png/g' "${WORK_DIR}/etc/lightdm/lightdm-gtk-greeter.conf"
sudo sed -i 's/#logo=/logo=\/usr\/share\/backgrounds\/enipla_logo.png/g' "${WORK_DIR}/etc/lightdm/lightdm-gtk-greeter.conf"

# 6. Install desktop environment and software
sudo chroot "${WORK_DIR}" /bin/bash << EOF
apt update
apt install -y enlightenment lightdm flatpak abiword gnumeric sylpheed zathura mpv xmms mtpaint gftp leafpad zzzfm peazip

# Install Flatpak apps
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.brave.Browser
flatpak install flathub 1  app.drey.Warp
flatpak install flathub org.kde.isoimagewriter
flatpak install flathub com.valvesoftware.Steam
EOF

# 7. Unmount the ISO
sudo umount "${WORK_DIR}"

echo "Customization complete. You can now build your ISO using Cubic."
