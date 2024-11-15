#!/bin/bash

# Variables for image paths
ENIPLA_BACKGROUND="../enipla_background.png"
ENIPLA_LOGO="../hd_enipla_logo_brand_transparent.png"

# Install prerequisites if they aren't already installed
echo "Installing necessary packages..."
sudo apt-get update
sudo apt-get install -y live-build git

# Clone the Lilidog repository
echo "Cloning Lilidog-Mirror repository..."
git clone https://github.com/Enipla/Lilidog-Mirror.git core
cd core || { echo "Failed to enter 'core' directory."; exit 1; }

# Replace specific images with enipla_background.png but keep the original filenames
echo "Replacing images with Enipla background while retaining original names..."
cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/usr/share/backgrounds/wallpapers/Pawprints.jpg"
cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/usr/share/backgrounds/grub-bg/Lili-Plain.png"
cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/boot/grub/Ozarkdog-grub.png"
cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/usr/share/backgrounds/grub-bg/Brown-paw.png"

# Replace specific logos with hd_enipla_logo_brand_transparent.png but keep the original filenames
echo "Replacing logos with Enipla logo while retaining original names..."
cp "$ENIPLA_LOGO" "config/includes.installer/usr/share/graphics/logo_debian_dark.png"
cp "$ENIPLA_LOGO" "config/includes.installer/usr/share/graphics/logo_debian.png"

# Update user-facing OS name from Lilidog to Enipla in specific files
echo "Updating specified files to display 'Enipla' instead of 'Lilidog'..."
target_files=(
    "config/includes.chroot_after_packages/etc/issue"
    "config/includes.chroot_after_packages/usr/share/lilidog/Readme.lilidog-themes"
    "config/includes.chroot_after_packages/usr/share/lilidog/welcome2.txt"
    "config/includes.chroot_after_packages/usr/share/lilidog/welcome.txt"
    "config/includes.chroot_after_packages/etc/lsb-release"
)

# Loop through specified files and replace "Lilidog" with "Enipla"
for file in "${target_files[@]}"; do
    if [ -f "$file" ]; then
        sed -i 's/Lilidog/Enipla/g' "$file"
    else
        echo "Warning: File $file not found."
    fi
done

# Update "Lilidog" to "Enipla" in all files within the Calamares branding directory
echo "Updating Calamares branding to Enipla..."
CALAMARES_BRANDING_PATH="config/includes.chroot_after_packages/etc/calamares/branding"
if [ -d "$CALAMARES_BRANDING_PATH" ]; then
    find "$CALAMARES_BRANDING_PATH" -type f -exec sed -i 's/Lilidog/Enipla/g' {} +
else
    echo "Warning: Calamares branding directory not found."
fi

# Build the ISO
echo "Building the Enipla OS ISO..."
sudo lb clean  # Clean previous builds
sudo lb config  # Configure the live-build
sudo lb build   # Build the ISO

# Notify the user of completion
if [ -f "./live-image-amd64.hybrid.iso" ]; then
    echo "Enipla OS ISO build complete: $(pwd)/live-image-amd64.hybrid.iso"
else
    echo "ISO build failed. Check the logs for more details."
fi
