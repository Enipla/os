#!/bin/bash

# Set paths for custom branding assets
ENIPLA_BACKGROUND="../enipla_background.png"
ENIPLA_LOGO="../hd_enipla_logo_brand_transparent.png"

# Function to configure the live-build
configure_build() {
    echo "Configuring live-build for Enipla..."
    lb config noauto \
        --apt-recommends 'false' \
        --apt-source-archives 'false' \
        --apt-indices 'false' \
        --archive-areas "main contrib non-free non-free-firmware" \
        --debian-installer 'live' \
        --debian-installer-distribution 'bookworm' \
        --distribution 'bookworm' \
        --mirror-binary 'https://deb.debian.org/debian' \
        --mirror-binary-security 'https://security.debian.org/debian-security' \
        --mirror-bootstrap 'https://deb.debian.org/debian' \
        --firmware-binary 'true' \
        --firmware-chroot 'true' \
        --security 'true' \
        --memtest 'memtest86+' \
        --iso-application 'Enipla GNU/Linux' \
        --iso-publisher 'Enipla Project' \
        --iso-volume 'Enipla OS 1.0' \
        --system 'live' \
        --win32-loader 'false' \
        --zsync 'false' \
        --quiet
}

# Function to build the ISO
build_iso() {
    echo "Building the ISO..."
    lb build noauto 2>&1 | tee build.log
    if [ -f "live-image-amd64.hybrid.iso" ]; then
        echo "Enipla OS ISO build complete: $(pwd)/live-image-amd64.hybrid.iso"
    else
        echo "ISO build failed. Check the logs for more details."
        exit 1
    fi
}

# Function to clean up previous build artifacts
clean_build() {
    echo "Cleaning up previous builds..."
    lb clean noauto
    rm -f config/binary config/bootstrap config/chroot config/common config/source
    rm -f build.log
}

# Replace branding assets and update text in the configuration files
apply_branding() {
    echo "Applying Enipla branding..."

    # Replace background images
    cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/usr/share/backgrounds/wallpapers/Pawprints.jpg"
    cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/usr/share/backgrounds/grub-bg/Lili-Plain.png"
    cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/boot/grub/Ozarkdog-grub.png"
    cp "$ENIPLA_BACKGROUND" "config/includes.chroot_after_packages/usr/share/backgrounds/grub-bg/Brown-paw.png"

    # Replace logos
    cp "$ENIPLA_LOGO" "config/includes.installer/usr/share/graphics/logo_debian_dark.png"
    cp "$ENIPLA_LOGO" "config/includes.installer/usr/share/graphics/logo_debian.png"

    # Update text branding
    local target_files=(
        "config/includes.chroot_after_packages/etc/issue"
        "config/includes.chroot_after_packages/usr/share/lilidog/Readme.lilidog-themes"
        "config/includes.chroot_after_packages/usr/share/lilidog/welcome2.txt"
        "config/includes.chroot_after_packages/usr/share/lilidog/welcome.txt"
        "config/includes.chroot_after_packages/etc/lsb-release"
    )
    for file in "${target_files[@]}"; do
        if [ -f "$file" ]; then
            sed -i 's/Lilidog/Enipla/g' "$file"
        else
            echo "Warning: File $file not found."
        fi
    done

    # Update Calamares branding
    local CALAMARES_BRANDING_PATH="config/includes.chroot_after_packages/etc/calamares/branding"
    if [ -d "$CALAMARES_BRANDING_PATH" ]; then
        find "$CALAMARES_BRANDING_PATH" -type f -exec sed -i 's/Lilidog/Enipla/g' {} +
    else
        echo "Warning: Calamares branding directory not found."
    fi
}

# Main script execution
main() {
    echo "Starting the Enipla OS build process..."

    # Step 1: Clean up any previous builds
    clean_build

    # Step 2: Configure the build
    configure_build

    # Step 3: Apply custom branding
    apply_branding

    # Step 4: Build the ISO
    build_iso

    echo "Enipla OS build process complete!"
}

# Run the main function
main
