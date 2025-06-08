#!/usr/bin/env bash

# DWM Desktop Environment Installer Script
# This script installs DWM, slstatus, st, dmenu and configures a complete desktop environment

set -e  # Exit on any unhandled error

# Enable logging
exec > >(tee -i dwm_install.log)
exec 2>&1

# Cool ASCII art banner
cat << 'EOF'

██████╗ ██╗    ██╗███╗   ███╗    ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
██╔══██╗██║    ██║████╗ ████║    ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
██║  ██║██║ █╗ ██║██╔████╔██║    ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
██║  ██║██║███╗██║██║╚██╔╝██║    ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
██████╔╝╚███╔███╔╝██║ ╚═╝ ██║    ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
╚═════╝  ╚══╝╚══╝ ╚═╝     ╚═╝    ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝

    ┌─────────────────────────────────────────────────────────────────┐
    │                  🚀 DWM Desktop Environment                     │
    │            Dynamic Window Manager Installation Script           │
    │                                                                 │
    │  📦 Installing: DWM + slstatus + st + dmenu + configurations   │
    │  🎨 Features: Patches, themes, wallpapers & complete setup     │
    │  ⚡ Fast, minimal, and highly customizable desktop experience   │
    └─────────────────────────────────────────────────────────────────┘

EOF

echo "🎯 Starting DWM installation process..."
echo "📋 This script will install and configure a complete tiling window manager setup"
echo

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then   
    echo "This script must be run as root. Please use sudo."
    exit 1
fi

# Get the actual user who ran sudo (if applicable)
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(eval echo ~$REAL_USER)

echo "Installing for user: $REAL_USER"
echo "User home directory: $REAL_HOME"

# Verify required directories exist
required_dirs=("dwm" "slstatus" "st" "dmenu" "patches" "scripts" "config" "etc" "usr")
for dir in "${required_dirs[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Required directory '$dir' not found. Please ensure you're running this from the kid_desktop repository root."
        exit 1
    fi
done

# Update the package list
echo "Updating package list..."
apt update || {
    echo "Failed to update package list. Exiting."
    exit 1
}

# Install necessary packages
echo "Installing build dependencies and required packages..."
apt install -y \
    build-essential \
    git \
    curl \
    wget \
    libx11-dev \
    libxft-dev \
    libxinerama-dev \
    libxrandr-dev \
    libx11-xcb-dev \
    libxcb1-dev \
    libxcb-util0-dev \
    xcb-util-wm \
    xcb-util-keysyms \
    xcb-util-cursor \
    xcb-util-image \
    xcb-util-renderutil \
    xcb-util-xrm \
    tint2 \
    feh \
    alsa-utils \
    picom \
    lxappearance \
    lxsession \
    dunst \
    thunar \

    fonts-noto \
    fonts-font-awesome \
    xorg \
    xinit || {
    echo "Failed to install necessary packages. Exiting."
    exit 1
}

# Detect distribution for package-specific installations
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi

echo "Detected distribution: $DISTRO"

# Install volumeicon based on distribution
echo "Installing volumeicon..."
case "$DISTRO" in
    ubuntu|debian)
        apt install -y volumeicon-alsa || {
            echo "Failed to install volumeicon-alsa, trying alternative..."
            apt install -y volumeicon || echo "Warning: Could not install volumeicon"
        }
        ;;
    *)
        # For MX Linux and other Debian-based distros
        apt install -y volumeicon || {
            echo "Failed to install volumeicon, trying alternative..."
            apt install -y volumeicon-alsa || echo "Warning: Could not install volumeicon"
        }
        ;;
esac

# Try to install nerd fonts (may not be available on all systems)
echo "Attempting to install Nerd Fonts..."
if apt install -y fonts-nerd-fonts-complete 2>/dev/null; then
    echo "Nerd Fonts installed successfully."
else
    echo "Nerd Fonts package not available, continuing without it."
fi

echo "=== Building DWM ==="
# Change to the dwm directory
cd dwm || { echo "Failed to change directory to dwm. Exiting."; exit 1; }

# Apply patches BEFORE compilation
echo "Applying DWM patches..."
if ls ../patches/*.diff 1> /dev/null 2>&1; then
    for patch in ../patches/*.diff; do
        echo "Applying patch: $(basename "$patch")"
        if patch -p1 < "$patch"; then
            echo "Successfully applied patch: $(basename "$patch")"
        else
            echo "Failed to apply patch: $(basename "$patch"). Continuing with next patch."
        fi
    done
else
    echo "No patches found in ../patches. Skipping patching."
fi

# Compile and install DWM
echo "Compiling and installing DWM..."
make clean install || {
    echo "Failed to compile and install DWM. Exiting."
    exit 1
}

# Clean up build files
make clean

# Move back to parent directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }

echo "=== Building slstatus ==="
# Change to slstatus directory
cd slstatus || { echo "Failed to change directory to slstatus. Exiting."; exit 1; }

# Compile and install slstatus
echo "Compiling and installing slstatus..."
make clean install || {
    echo "Failed to compile and install slstatus. Exiting."
    exit 1
}

# Clean up build files
make clean

# Move back to parent directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }

echo "=== Building st (terminal) ==="
# Change to st directory
cd st || { echo "Failed to change directory to st. Exiting."; exit 1; }

# Compile and install st
echo "Compiling and installing st..."
make clean install || {
    echo "Failed to compile and install st. Exiting."
    exit 1
}

# Clean up build files
make clean

# Move back to parent directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }

echo "=== Building dmenu ==="
# Change to dmenu directory
cd dmenu || { echo "Failed to change directory to dmenu. Exiting."; exit 1; }

# Compile and install dmenu
echo "Compiling and installing dmenu..."
make clean install || {
    echo "Failed to compile and install dmenu. Exiting."
    exit 1
}

# Clean up build files
make clean

# Move back to parent directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }

echo "=== Installing Scripts ==="
# Copy contents of scripts folder to /usr/local/bin (better practice than /usr/bin)
echo "Copying scripts to /usr/local/bin..."   
if [ -d "scripts" ] && [ "$(ls -A scripts)" ]; then
    cp scripts/* /usr/local/bin/ || {
        echo "Failed to copy scripts to /usr/local/bin. Exiting."
        exit 1
    }
    
    # Set permissions for the scripts
    echo "Setting permissions for scripts..."
    chmod +x /usr/local/bin/* || {
        echo "Failed to set permissions for scripts. Exiting."
        exit 1
    }
else
    echo "No scripts found to install."
fi

echo "=== Setting up systemd services ==="
# Create /etc/systemd/user if not created and copy systemd service file
echo "Setting up systemd user services..."
mkdir -p /etc/systemd/user || {
    echo "Failed to create /etc/systemd/user. Exiting."
    exit 1
}

if [ -f "etc/systemd/user/dwm-session.service" ]; then
    cp etc/systemd/user/dwm-session.service /etc/systemd/user/ || {
        echo "Failed to copy systemd service file. Exiting."
        exit 1
    }
    echo "Systemd service file installed."
else
    echo "Warning: dwm-session.service not found, skipping."
fi

echo "=== Setting up user configuration ==="
# Create the necessary directories under user's .config
echo "Creating configuration directories for user $REAL_USER..."
sudo -u "$REAL_USER" mkdir -p \
    "$REAL_HOME/.config/dunst" \
    "$REAL_HOME/.config/lxsession/LXDE" \
    "$REAL_HOME/.config/lxappearance" \
    "$REAL_HOME/.config/systemd/user" \
    "$REAL_HOME/.config/picom" \
    "$REAL_HOME/.config/tint2" \
    "$REAL_HOME/.config/gtk-3.0" \
    "$REAL_HOME/.config/gtk-4.0" || {
    echo "Failed to create configuration directories. Exiting."
    exit 1
}

# Copy configuration files to user's directories
echo "Copying configuration files..."
if [ -d "config/dunst" ]; then
    sudo -u "$REAL_USER" cp -r config/dunst/* "$REAL_HOME/.config/dunst/" 2>/dev/null || echo "No dunst config found"
fi

if [ -d "config/picom" ]; then
    sudo -u "$REAL_USER" cp -r config/picom/* "$REAL_HOME/.config/picom/" 2>/dev/null || echo "No picom config found"
fi

if [ -d "config/tint2" ]; then
    sudo -u "$REAL_USER" cp -r config/tint2/* "$REAL_HOME/.config/tint2/" 2>/dev/null || echo "No tint2 config found"
fi

echo "=== Display Manager Setup ==="
# Choose display manager
echo "Please choose a display manager:"
echo "1) lightdm (recommended)"
echo "2) sddm"
echo "3) gdm3"
echo "4) Skip display manager setup (use startx)"
read -p "Enter your choice (1/2/3/4): " display_manager_choice

case "$display_manager_choice" in
    1)
        echo "Installing lightdm..."
        apt install -y lightdm lightdm-gtk-greeter || {
            echo "Failed to install lightdm. Exiting."
            exit 1
        }
        systemctl enable lightdm
        ;;
    2)
        echo "Installing sddm..."
        apt install -y sddm || {
            echo "Failed to install sddm. Exiting."
            exit 1
        }
        systemctl enable sddm
        ;;
    3)
        echo "Installing gdm3..."
        apt install -y gdm3 || {
            echo "Failed to install gdm3. Exiting."
            exit 1
        }
        systemctl enable gdm3
        ;;
    4)
        echo "Skipping display manager installation."
        echo "You can start DWM manually with 'startx' command."
        ;;
    *)
        echo "Invalid choice. Skipping display manager setup."
        ;;
esac

# Install desktop entry for DWM
echo "Installing DWM desktop entry..."
if [ -f "usr/share/xsessions/dwm.desktop" ]; then
    mkdir -p /usr/share/xsessions
    cp usr/share/xsessions/dwm.desktop /usr/share/xsessions/ || {
        echo "Failed to copy DWM desktop entry. Exiting."
        exit 1
    }
    echo "DWM desktop entry installed successfully."
else
    echo "Warning: dwm.desktop file not found in usr/share/xsessions/, creating default..."
    mkdir -p /usr/share/xsessions
    cat > /usr/share/xsessions/dwm.desktop << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=DWM
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
    echo "Default DWM desktop entry created."
fi

echo "=== Font Setup ==="
# Update the font cache
echo "Updating font cache..."
fc-cache -fv || {
    echo "Warning: Failed to update font cache, continuing..."
}

echo "=== Wallpaper Setup ==="
# Handle wallpaper installation and ask one of three options.  Use your own files in ~/Pictures/wallpapers/, get git from https://github.com/JaKooLit/Wallpaper-Bank.git or https://github.com/SCFUCHS87/ukiyo-e_backgrounds.git.
echo "Please choose a wallpaper setup option:"
echo "1) Use your own wallpapers from ~/Pictures/wallpapers/"
echo "2) Download wallpapers from JaKooLit's Wallpaper Bank"
echo "3) Download ukiyo-e backgrounds from SCFUCHS87"
echo "4) Skip wallpaper setup"
read -p "Enter your choice (1/2/3/4): " wallpaper_choice
#  Create wallpapers directory if it doesn't exist and you do not choose option 4
if [ ! -d "$REAL_HOME/Pictures/wallpapers" ]; then
    mkdir -p "$REAL_HOME/Pictures/wallpapers"
fi
#  Handle the user's choice by cloning the appropriate repository or skipping and then moving the wallpapers folder in each repository to the user's wallpapers directory
case "$wallpaper_choice" in
    1)
        echo "Using your own wallpapers from ~/Pictures/wallpapers/"
        echo "Make sure to place your wallpapers in $REAL_HOME/Pictures/wallpapers/"
        ;;
    2)
        echo "Downloading wallpapers from JaKooLit's Wallpaper Bank..."
        if git clone  https://github.com/JaKooLit/Wallpaper-Bank.git "$REAL_HOME/Pictures/wallpapers/Wallpaper-Bank"; then
            echo "Wallpapers downloaded successfully."
            mv "$REAL_HOME/Pictures/wallpapers/Wallpaper-Bank/"* "$REAL_HOME/Pictures/wallpapers/"
            rm -rf "$REAL_HOME/Pictures/wallpapers/Wallpaper-Bank"
        else
            echo "Failed to download wallpapers from JaKooLit. Exiting."
            exit 1
        fi
        ;;
    3)
        echo "Downloading ukiyo-e backgrounds from SCFUCHS87..."
        if git clone https://github.com/SCFUCHS87/ukiyo-e_backgrounds.git
    "$REAL_HOME/Pictures/wallpapers/ukiyo-e_backgrounds"; then
                echo "Ukiyo-e backgrounds downloaded successfully."
                mv "$REAL_HOME/Pictures/wallpapers/ukiyo-e_backgrounds/"* "$REAL_HOME/Pictures/wallpapers/"
                rm -rf "$REAL_HOME/Pictures/wallpapers/ukiyo-e_backgrounds"
            else
                echo "Failed to download ukiyo-e backgrounds from SCFUCHS87. Exiting."
                exit 1
            fi
        ;;
    4)
        echo "Skipping wallpaper setup. You can manually add wallpapers to $REAL_HOME/Pictures/wallpapers/"
        ;;
    *)
        echo "Invalid choice. Skipping wallpaper setup."
        ;;
esac    

# If you chose option 3 please install set_wallpaper_resolution.sh to $HOME/bin/set_wallpaper_resolution.sh
echo "Setting up wallpaper using feh..."
if [ -x "$REAL_HOME/bin/set_wallpaper_resolution.sh" ]; then
    echo "Running resolution-aware wallpaper script..."
    SELECTED_WALLPAPER=$("$REAL_HOME/bin/set_wallpaper_resolution.sh" --print-only)
else
    echo "No resolution-aware wallpaper script found. Picking random wallpaper..."
    SELECTED_WALLPAPER=$(find "$REAL_HOME/Pictures/wallpapers" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)
fi

# CHMOD the script to be executable
chmod +x "$REAL_HOME/bin/set_wallpaper_resolution.sh"

# For any option chosen install wpg-feh-random.sh to /usr/bin/wpg-feh-random.sh and set it to be excutable.
echo "Installing wpg-feh-random.sh script..."
if [ -f "scripts/wpg-feh-random.sh" ]; then
    cp scripts/wpg-feh-random.sh /usr/bin/wpg-feh-random.sh || {
        echo "Failed to copy wpg-feh-random.sh script. Exiting."
        exit 1
    }
    chmod +x /usr/bin/wpg-feh-random.sh || {
        echo "Failed to set permissions for wpg-feh-random.sh. Exiting."
        exit 1
    }
    echo "wpg-feh-random.sh script installed successfully."
else
    echo "Warning: wpg-feh-random.sh script not found in scripts/. Skipping installation."
fi

# Complete installation

echo "=== Installation Complete ==="
echo
echo "✅ DWM desktop environment installation completed successfully!"
echo
echo "=== Next Steps ==="
echo "1. Reboot your system"
echo "2. Select 'DWM' from your login screen"
echo "3. Use these key bindings to get started:"
echo "   - Alt+p: Launch dmenu (application launcher)"
echo "   - Alt+Shift+Enter: Open terminal (st)"
echo "   - Alt+Shift+c: Close window"
echo "   - Alt+Shift+q: Quit DWM"
echo
echo "=== Configuration Files ==="
echo "- DWM config: Edit dwm/config.h and recompile"
echo "- User configs: ~/.config/picom/, ~/.config/dunst/, etc."
echo "- Wallpapers: ~/Pictures/wallpapers/"
echo
echo "=== Logs ==="
echo "Installation log saved to: $(pwd)/dwm_install.log"
echo
echo "Enjoy your new DWM desktop environment!"