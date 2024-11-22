#!/bin/bash

apt update
apt upgrade -y

apt install -y enlightenment lightdm lightdm-gtk-greeter \
              abiword gnumeric sylpheed zathura mpv xmms mtpaint gftp leafpad zzzfm peazip \
              flatpak wget neofetch htop

systemctl enable lightdm

wget -O /usr/share/backgrounds/enipla_background.png https://github.com/Enipla/os/raw/main/enipla_background.png
wget -O /usr/share/icons/enipla_logo.png https://github.com/Enipla/os/raw/main/hd_enipla_logo_icon_transparent.png

feh --bg-fill /usr/share/backgrounds/enipla_background.png

cat << EOF > /etc/lightdm/lightdm-gtk-greeter.conf
[greeter]
background=/usr/share/backgrounds/enipla_background.png
logo=/usr/share/icons/enipla_logo.png
theme-name=Adwaita
icon-theme-name=Adwaita
font-name=Sans 10
user-font-name=Sans 12
EOF

sed -i 's/Debian GNU\/Linux/Enipla "Begone"/g' /etc/issue
sed -i 's/Debian GNU\/Linux/Enipla "Begone"/g' /etc/os-release

echo "enipla" > /etc/hostname
hostnamectl set-hostname enipla

cat << EOF > /etc/motd
Welcome to Enipla "Begone"!

An OS powered by hopes and dreams :)
EOF

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.brave.Browser -y
flatpak install flathub 1  app.drey.Warp -y
flatpak install flathub org.kde.isoimagewriter -y
flatpak install flathub com.valvesoftware.Steam -y

apt autoremove -y
