#!/usr/bin/env bash

# This script installs the DWM window manager and its dependencies.

# Check if the script is run as root
if [ "$(id -u)" -ne 0 ]; then   
    echo "This script must be run as root. Please use sudo."
    exit 1
fi  

# Update the package list
echo "Updating package list..."
apt update  
if [ $? -ne 0 ]; then
    echo "Failed to update package list. Exiting."
    exit 1
fi  
# Install necessary packages
echo "Installing necessary packages..."
apt install -y build-essential libx11-dev libxft-dev libxinerama-dev libxrandr-dev libx11-xcb-dev libxcb1-dev libxcb-util0-dev xcb-util-wm xcb-util-keysyms xcb-util-cursor xcb-util-image xcb-util-renderutil xcb-util-xrm
if [ $? -ne 0 ]; then
    echo "Failed to install necessary packages. Exiting."
    exit 1
fi      
# Change to the dwm directory of kid_desktop
cd dwm || { echo "Failed to change directory to dwm. Exiting."; exit 1; }   
# Compile and install DWM
echo "Compiling and installing DWM..."
make clean install
if [ $? -ne 0 ]; then
    echo "Failed to compile and install DWM. Exiting."
    exit 1
fi  
# Patch DWM with all the provided .diff files located in the patches folder    

echo "Patching DWM with provided patches..."
for patch in ../patches/*.diff; do
    if [ -f "$patch" ]; then
        echo "Applying patch: $patch"
        patch -p1 < "$patch"
        if [ $? -ne 0 ]; then
            echo "Failed to apply patch: $patch. Continuing with next patch."
        else
            echo "Successfully applied patch: $patch"
        fi
    else
        echo "No patches found in ../patches. Skipping patching."
    fi
done    

# Clean up
echo "Cleaning up..."
make clean
if [ $? -ne 0 ]; then
    echo "Failed to clean up. Exiting."
    exit 1
fi      

# Run dwm make clean install
echo "Running make clean install for DWM..."
make clean install
if [ $? -ne 0 ]; then
    echo "Failed to run make clean install for DWM. Exiting."
    exit 1
fi      
# Move back one directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }          

# Change to slstatus directory
cd slstatus || { echo "Failed to change directory to slstatus. Exiting."; exit 1; }     

# Compile and install slstatus
echo "Compiling and installing slstatus..."
make clean install
if [ $? -ne 0 ]; then
    echo "Failed to compile and install slstatus. Exiting."
    exit 1
fi  

# Clean up
echo "Cleaning up slstatus..."
make clean
if [ $? -ne 0 ]; then
    echo "Failed to clean up slstatus. Exiting."
    exit 1
fi      

# Move back one directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }          

# Change to st directory
cd st || { echo "Failed to change directory to st. Exiting."; exit 1; }         
# Compile and install st
echo "Compiling and installing st..."
make clean install
if [ $? -ne 0 ]; then
    echo "Failed to compile and install st. Exiting."
    exit 1
fi  
# Clean up
echo "Cleaning up st..."
make clean          

if [ $? -ne 0 ]; then
    echo "Failed to clean up st. Exiting."
    exit 1
fi

# Move back one directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }      
# Change to dmenu directory




cd dmenu || { echo "Failed to change directory to dmenu. Exiting."; exit 1; }
# Compile and install dmenu
echo "Compiling and installing dmenu..."
make clean install
if [ $? -ne 0 ]; then
    echo "Failed to compile and install dmenu. Exiting."
    exit 1
fi
# Clean up
echo "Cleaning up dmenu..."
make clean
if [ $? -ne 0 ]; then
    echo "Failed to clean up dmenu. Exiting."
    exit 1
fi  

# Move back one directory
cd .. || { echo "Failed to change directory back. Exiting."; exit 1; }    

# Check if other packages are installed:  tint2, feh, amixer, and piccom.
echo "Checking for additional packages: tint2, feh, amixer, picom..."
for package in tint2 feh amixer picom; do
    if ! command -v "$package" &> /dev/null; then
        echo "$package is not installed. Installing..."
        apt install -y "$package"
        if [ $? -ne 0 ]; then
            echo "Failed to install $package. Exiting."
            exit 1
        fi
    else
        echo "$package is already installed."
    fi
done    

# Deside which display manager to use with options: sddm, lightdm, gdm3
echo "Please choose a display manager to use:"
echo "1) sddm"
echo "2) lightdm"
echo "3) gdm3"
read -p "Enter your choice (1/2/3): " display_manager_choice        

case "$display_manager_choice" in
    1)
        echo "Installing sddm..."
        apt install -y sddm
        if [ $? -ne 0 ]; then
            echo "Failed to install sddm. Exiting."
            exit 1
        fi
        ;;
    2)
        echo "Installing lightdm..."
        apt install -y lightdm
        if [ $? -ne 0 ]; then
            echo "Failed to install lightdm. Exiting."
            exit 1
        fi
        ;;
    3)
        echo "Installing gdm3..."
        apt install -y gdm3
        if [ $? -ne 0 ]; then
            echo "Failed to install gdm3. Exiting."
            exit 1
        fi
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac    
# Enable the chosen display manager
echo "Enabling the chosen display manager..."
if [ "$display_manager_choice" -eq 1 ]; then
    systemctl enable sddm
elif [ "$display_manager_choice" -eq 2 ]; then
    systemctl enable lightdm
elif [ "$display_manager_choice" -eq 3 ]; then
    systemctl enable gdm3
fi  
# complete dpkg-reconfigure for the chosen display manager
echo "Reconfiguring the chosen display manager..."
if [ "$display_manager_choice" -eq 1 ]; then
    dpkg-reconfigure sddm
elif [ "$display_manager_choice" -eq 2 ]; then
    dpkg-reconfigure lightdm
elif [ "$display_manager_choice" -eq 3 ]; then
    dpkg-reconfigure gdm3
fi  

# Copy contents of scripts folder to /usr/bin/

echo "Copying scripts to /usr/bin..."   
mkdir -p /usr/bin/
cp -r scripts/* /usr/bin/
if [ $? -ne 0 ]; then
    echo "Failed to copy scripts to /usr/bin. Exiting."
    exit 1
fi      
# Set permissions for the scripts
echo "Setting permissions for scripts..."
chmod +x /usr/bin/*
if [ $? -ne 0 ]; then
    echo "Failed to set permissions for scripts. Exiting."
    exit 1
fi      

# Create /etc/systemd/user if not created and copy systemd service file from git /kid_desktop/etc/systemd/user/ to /etc/systemd/user/
echo "Creating /etc/systemd/user if it does not exist..."
mkdir -p /etc/systemd/user
if [ $? -ne 0 ]; then
    echo "Failed to create /etc/systemd/user. Exiting."
    exit 1
fi  
echo "Copying systemd service file to /etc/systemd/user..."
cp etc/systemd/user/dwm-session.service  /etc/systemd/user/
if [ $? -ne 0 ]; then
    echo "Failed to copy systemd service file. Exiting."
    exit 1
fi

# Install lxappearance, lxsession, dunst
echo "Installing lxappearance, lxsession, and dunst..."
apt install -y lxappearance lxsession dunst
if [ $? -ne 0 ]; then
    echo "Failed to install lxappearance, lxsession, or dunst. Exiting."
    exit 1
fi  

# Install nerd fonts from apt   
echo "Installing Nerd Fonts..."
apt install -y fonts-nerd-fonts-complete
if [ $? -ne 0 ]; then
    echo "Failed to install Nerd Fonts. Exiting."
    exit 1
fi  

# Update the font cache
echo "Updating font cache..."
fc-cache -fv
if [ $? -ne 0 ]; then
    echo "Failed to update font cache. Exiting."
    exit 1
fi      

# Create the necessary directories under .config to match the structure of kid_desktop
echo "Creating necessary directories under ~/.config..."
mkdir -p ~/.config/dunst
mkdir -p ~/.config/lxsession/LXDE
mkdir -p ~/.config/lxappearance
mkdir -p ~/.config/systemd/user
mkdir -p ~/.config/picom
mkdir -p ~/.config/tint2
mkdir -p ~/.config/gtk-3.0
mkdir -p ~/.config/gtk-4.0
if [ $? -ne 0 ]; then
    echo "Failed to create necessary directories under ~/.config. Exiting."
    exit 1
fi      

# Copy the configuration files from kid_desktop to the respective directories
echo "Copying configuration files to ~/.config..."
cp -r config/dunst/* ~/.config/dunst/
cp -r config/picom/* ~/.config/picom/
cp -r config/tint2/* ~/.config/tint2/

# Check if installed and if not install Thunar
if ! command -v thunar &> /dev/null; then
    echo "Thunar is not installed. Installing Thunar..."
    apt install -y thunar
    if [ $? -ne 0 ]; then
        echo "Failed to install Thunar. Exiting."
        exit 1
    fi
else
    echo "Thunar is already installed."
fi

# Ensure volumeicon is installed
if ! command -v volumeicon &> /dev/null; then
    echo "Volumeicon is not installed. Installing Volumeicon..."
    apt install -y volumeicon
    if [ $? -ne 0 ]; then
        echo "Failed to install Volumeicon. Exiting."
        exit 1          
    fi
else
    echo "Volumeicon is already installed."
fi      

# Ask if they want to install the wallpapers
read -p "Do you want to install the wallpapers? (y/n): " install_wallpapers