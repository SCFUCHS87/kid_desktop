#!/bin/bash

# DWM Desktop Environment Installer Script
# This script installs DWM, slstatus, st, dmenu and configures a complete desktop environment
# Enhanced with better error handling, logging, and validation

set -euo pipefail  # Exit on error, undefined vars, and pipe failures

# Configuration
LOG_FILE="./dwm_install.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Initialize logging
mkdir -p "$(dirname "$LOG_FILE")"
exec > >(tee -a "$LOG_FILE")
exec 2>&1

# Logging function
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message"
    
    if [[ "$level" == "ERROR" ]]; then
        echo "[$level] $message" >&2
    fi
}

# Error handling function
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

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

log "INFO" "Starting DWM installation process..."
log "INFO" "This script will install and configure a complete tiling window manager setup"

# Check if the script is run as root
if [[ "$(id -u)" -ne 0 ]]; then   
    error_exit "This script must be run as root. Please use sudo."
fi

# Get the actual user who ran sudo (if applicable)
REAL_USER=${SUDO_USER:-$(whoami)}
REAL_HOME=$(eval echo ~$REAL_USER)

log "INFO" "Installing for user: $REAL_USER"
log "INFO" "User home directory: $REAL_HOME"
log "INFO" "Script directory: $SCRIPT_DIR"

# Check essential dependencies before starting
check_dependencies() {
    log "INFO" "Checking essential dependencies..."
    
    local missing_deps=()
    local essential_commands=("make" "gcc" "git" "apt")
    
    for cmd in "${essential_commands[@]}"; do
        if ! command_exists "$cmd"; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -ne 0 ]]; then
        error_exit "Missing essential dependencies: ${missing_deps[*]}"
    fi
    
    log "INFO" "Essential dependencies check passed"
}

# Validate repository structure
validate_repository() {
    log "INFO" "Validating repository structure..."
    
    local required_dirs=("dwm" "slstatus" "st" "dmenu" "scripts" "config")
    local missing_dirs=()
    
    for dir in "${required_dirs[@]}"; do
        local full_path="$SCRIPT_DIR/$dir"
        if [[ ! -d "$full_path" ]]; then
            missing_dirs+=("$dir")
        fi
    done
    
    if [[ ${#missing_dirs[@]} -ne 0 ]]; then
        error_exit "Missing required directories: ${missing_dirs[*]}. Please ensure you're running this from the kid_desktop repository root."
    fi
    
    # Check for Makefiles in build directories
    local build_dirs=("dwm" "slstatus" "st" "dmenu")
    for dir in "${build_dirs[@]}"; do
        if [[ ! -f "$SCRIPT_DIR/$dir/Makefile" ]]; then
            log "WARN" "No Makefile found in $dir directory"
        fi
    done
    
    log "INFO" "Repository structure validation passed"
}

# Install system packages with better error handling
install_packages() {
    log "INFO" "Updating package list..."
    if ! apt update; then
        error_exit "Failed to update package list"
    fi

    log "INFO" "Installing build dependencies and required packages..."
    local packages=(
        build-essential git curl wget
        libx11-dev libxft-dev libxinerama-dev libxrandr-dev
        libx11-xcb-dev libxcb1-dev libxcb-util0-dev
        libxcb-util-dev libxcb-keysyms1-dev libxcb-cursor-dev
        libxcb-image0-dev libxcb-render-util0-dev libxcb-xrm-dev
        tint2 feh alsa-utils picom lxappearance lxsession
        dunst thunar fonts-noto fonts-font-awesome xorg xinit
    )
    
    if ! apt install -y "${packages[@]}"; then
        error_exit "Failed to install necessary packages"
    fi

    # Detect distribution for package-specific installations
    local distro="unknown"
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release
        distro="$ID"
    fi

    log "INFO" "Detected distribution: $distro"

    # Install volumeicon based on distribution
    log "INFO" "Installing volumeicon..."
    case "$distro" in
        ubuntu|debian)
            apt install -y volumeicon-alsa || apt install -y volumeicon || log "WARN" "Could not install volumeicon"
            ;;
        *)
            apt install -y volumeicon || apt install -y volumeicon-alsa || log "WARN" "Could not install volumeicon"
            ;;
    esac

    # Try to install nerd fonts (may not be available on all systems)
    log "INFO" "Attempting to install Nerd Fonts..."
    if apt install -y fonts-nerd-fonts-complete 2>/dev/null; then
        log "INFO" "Nerd Fonts installed successfully"
    else
        log "INFO" "Nerd Fonts package not available, continuing without it"
    fi
}

# Build component with error handling
build_component() {
    local component="$1"
    local component_dir="$SCRIPT_DIR/$component"
    
    log "INFO" "Building $component..."
    
    if [[ ! -d "$component_dir" ]]; then
        error_exit "Component directory not found: $component_dir"
    fi
    
    cd "$component_dir" || error_exit "Failed to change to $component directory"
    
    # Apply patches if this is DWM and patches exist
    if [[ "$component" == "dwm" ]]; then
        apply_dwm_patches
    fi
    
    # Clean previous builds
    if ! make clean 2>/dev/null; then
        log "WARN" "No previous build to clean for $component"
    fi
    
    # Compile and install
    if ! make install; then
        error_exit "Failed to compile and install $component"
    fi
    
    # Clean build files
    make clean 2>/dev/null || true
    
    log "INFO" "$component built and installed successfully"
    
    cd "$SCRIPT_DIR" || error_exit "Failed to return to script directory"
}

# Apply DWM patches
apply_dwm_patches() {
    local patches_dir="$SCRIPT_DIR/patches"
    
    if [[ ! -d "$patches_dir" ]]; then
        log "INFO" "No patches directory found, skipping patch application"
        return 0
    fi
    
    log "INFO" "Applying DWM patches..."
    
    local patch_count=0
    local successful_patches=0
    
    for patch in "$patches_dir"/*.diff; do
        if [[ -f "$patch" ]]; then
            ((patch_count++))
            log "INFO" "Applying patch: $(basename "$patch")"
            
            if patch -p1 < "$patch" 2>/dev/null; then
                log "INFO" "Successfully applied patch: $(basename "$patch")"
                ((successful_patches++))
            else
                log "WARN" "Failed to apply patch: $(basename "$patch")"
            fi
        fi
    done
    
    if [[ $patch_count -eq 0 ]]; then
        log "INFO" "No patches found in $patches_dir"
    else
        log "INFO" "Applied $successful_patches out of $patch_count patches"
    fi
}

# Install scripts with proper error handling
install_scripts() {
    log "INFO" "Installing scripts..."
    
    local scripts_dir="$SCRIPT_DIR/scripts"
    
    if [[ ! -d "$scripts_dir" ]] || [[ -z "$(ls -A "$scripts_dir" 2>/dev/null)" ]]; then
        log "WARN" "No scripts found to install"
        return 0
    fi
    
    # Copy scripts to /usr/bin/ (changed from /usr/local/bin/ for system-wide access)
    for script in "$scripts_dir"/*; do
        if [[ -f "$script" ]]; then
            local script_name=$(basename "$script")
            log "INFO" "Installing $script_name to /usr/bin/"
            
            if cp "$script" "/usr/bin/$script_name" 2>/dev/null; then
                chmod +x "/usr/bin/$script_name"
                log "INFO" "Successfully installed $script_name"
            else
                log "ERROR" "Failed to install $script_name"
            fi
        fi
    done
    
    # Special handling for wallpaper script
    install_wallpaper_script
}

# Install wallpaper script specifically
install_wallpaper_script() {
    local wallpaper_script="$SCRIPT_DIR/scripts/set_wallpaper_resolution.sh"
    
    if [[ -f "$wallpaper_script" ]]; then
        log "INFO" "Installing wallpaper resolution script to /usr/bin/"
        
        if cp "$wallpaper_script" /usr/bin/set_wallpaper_resolution.sh 2>/dev/null; then
            chmod +x /usr/bin/set_wallpaper_resolution.sh
            log "INFO" "Wallpaper script installed successfully to /usr/bin/"
        else
            log "ERROR" "Failed to install wallpaper script"
        fi
    else
        log "WARN" "Wallpaper script not found at $wallpaper_script"
    fi
}

# Setup systemd services
setup_systemd_services() {
    log "INFO" "Setting up systemd services..."
    
    mkdir -p /etc/systemd/user || error_exit "Failed to create /etc/systemd/user"
    
    local service_file="$SCRIPT_DIR/etc/systemd/user/dwm-session.service"
    if [[ -f "$service_file" ]]; then
        if cp "$service_file" /etc/systemd/user/ 2>/dev/null; then
            log "INFO" "Systemd service file installed"
        else
            error_exit "Failed to copy systemd service file"
        fi
    else
        log "WARN" "dwm-session.service not found, skipping"
    fi
}

# Setup user configuration
setup_user_config() {
    log "INFO" "Setting up user configuration for $REAL_USER..."
    
    # Create configuration directories
    local config_dirs=(
        "$REAL_HOME/.config/dunst"
        "$REAL_HOME/.config/lxsession/LXDE"
        "$REAL_HOME/.config/lxappearance"
        "$REAL_HOME/.config/systemd/user"
        "$REAL_HOME/.config/picom"
        "$REAL_HOME/.config/tint2"
        "$REAL_HOME/.config/gtk-3.0"
        "$REAL_HOME/.config/gtk-4.0"
    )
    
    for config_dir in "${config_dirs[@]}"; do
        if ! sudo -u "$REAL_USER" mkdir -p "$config_dir"; then
            log "ERROR" "Failed to create $config_dir"
        fi
    done
    
    # Ensure .config directory exists and has correct ownership
    sudo -u "$REAL_USER" mkdir -p "$REAL_HOME/.config"
    
    # Copy configuration files
    local config_source="$SCRIPT_DIR/config"
    
    for config_type in dunst picom tint2; do
        local source_dir="$config_source/$config_type"
        local target_dir="$REAL_HOME/.config/$config_type"
        
        if [[ -d "$source_dir" ]]; then
            log "INFO" "Copying $config_type configuration..."
            if sudo -u "$REAL_USER" cp -r "$source_dir"/* "$target_dir/" 2>/dev/null; then
                log "INFO" "$config_type configuration copied successfully"
            else
                log "WARN" "Failed to copy $config_type configuration"
            fi
        else
            log "INFO" "No $config_type configuration found"
        fi
    done
    
    # Fix ownership of all config files
    chown -R "$REAL_USER:$REAL_USER" "$REAL_HOME/.config" 2>/dev/null || log "WARN" "Could not fix config file ownership"
}

# Setup display manager
setup_display_manager() {
    log "INFO" "Setting up display manager..."
    
    # Check if running in non-interactive mode
    if [[ ! -t 0 ]]; then
        log "INFO" "Non-interactive mode detected, skipping display manager setup"
        return 0
    fi
    
    echo "Please choose a display manager:"
    echo "1) lightdm (recommended)"
    echo "2) sddm"
    echo "3) gdm3"
    echo "4) Skip display manager setup (use startx)"
    read -p "Enter your choice (1/2/3/4): " display_manager_choice

    case "$display_manager_choice" in
        1)
            log "INFO" "Installing lightdm..."
            if apt install -y lightdm lightdm-gtk-greeter 2>/dev/null; then
                systemctl enable lightdm 2>/dev/null || log "WARN" "Failed to enable lightdm"
                log "INFO" "lightdm installed and enabled"
            else
                error_exit "Failed to install lightdm"
            fi
            ;;
        2)
            log "INFO" "Installing sddm..."
            if apt install -y sddm 2>/dev/null; then
                systemctl enable sddm 2>/dev/null || log "WARN" "Failed to enable sddm"
                log "INFO" "sddm installed and enabled"
            else
                error_exit "Failed to install sddm"
            fi
            ;;
        3)
            log "INFO" "Installing gdm3..."
            if apt install -y gdm3; then
                systemctl enable gdm3
                log "INFO" "gdm3 installed and enabled"
            else
                error_exit "Failed to install gdm3"
            fi
            ;;
        4)
            log "INFO" "Skipping display manager installation"
            log "INFO" "You can start DWM manually with 'startx' command"
            ;;
        *)
            log "WARN" "Invalid choice. Skipping display manager setup"
            ;;
    esac
}

# Install desktop entry
install_desktop_entry() {
    log "INFO" "Installing DWM desktop entry..."
    
    mkdir -p /usr/share/xsessions
    
    local desktop_file="$SCRIPT_DIR/usr/share/xsessions/dwm.desktop"
    
    if [[ -f "$desktop_file" ]]; then
        if cp "$desktop_file" /usr/share/xsessions/ 2>/dev/null; then
            log "INFO" "DWM desktop entry installed successfully"
        else
            error_exit "Failed to copy DWM desktop entry"
        fi
    else
        log "WARN" "dwm.desktop file not found, creating default..."
        cat > /usr/share/xsessions/dwm.desktop << 'EOF'
[Desktop Entry]
Encoding=UTF-8
Name=DWM
Comment=Dynamic Window Manager
Exec=dwm
Icon=dwm
Type=XSession
EOF
        log "INFO" "Default DWM desktop entry created"
    fi
}

# Setup wallpapers
setup_wallpapers() {
    log "INFO" "Setting up wallpapers..."
    
    # Create wallpapers directory
    local wallpaper_dir="$REAL_HOME/Pictures/wallpapers"
    sudo -u "$REAL_USER" mkdir -p "$wallpaper_dir"
    
    # Check if running in non-interactive mode
    if [[ ! -t 0 ]]; then
        log "INFO" "Non-interactive mode detected, skipping wallpaper setup"
        return 0
    fi
    
    echo "Please choose a wallpaper setup option:"
    echo "1) Use your own wallpapers from ~/Pictures/wallpapers/"
    echo "2) Download wallpapers from JaKooLit's Wallpaper Bank"
    echo "3) Download ukiyo-e backgrounds from SCFUCHS87"
    echo "4) Skip wallpaper setup"
    read -p "Enter your choice (1/2/3/4): " wallpaper_choice
    
    case "$wallpaper_choice" in
        1)
            log "INFO" "Using your own wallpapers from ~/Pictures/wallpapers/"
            log "INFO" "Make sure to place your wallpapers in $wallpaper_dir"
            ;;
        2)
            log "INFO" "Downloading wallpapers from JaKooLit's Wallpaper Bank..."
            local temp_dir="$wallpaper_dir/temp_download"
            
            if sudo -u "$REAL_USER" git clone https://github.com/JaKooLit/Wallpaper-Bank.git "$temp_dir" 2>/dev/null; then
                log "INFO" "Wallpapers downloaded successfully"
                sudo -u "$REAL_USER" cp -r "$temp_dir"/* "$wallpaper_dir/"
                sudo -u "$REAL_USER" rm -rf "$temp_dir"
                log "INFO" "Wallpapers installed to $wallpaper_dir"
            else
                error_exit "Failed to download wallpapers from JaKooLit"
            fi
            ;;
        3)
            log "INFO" "Downloading ukiyo-e backgrounds from SCFUCHS87..."
            local temp_dir="$wallpaper_dir/temp_download"
            
            if sudo -u "$REAL_USER" git clone https://github.com/SCFUCHS87/ukiyo-e_backgrounds.git "$temp_dir" 2>/dev/null; then
                log "INFO" "Ukiyo-e backgrounds downloaded successfully"
                sudo -u "$REAL_USER" cp -r "$temp_dir"/* "$wallpaper_dir/"
                sudo -u "$REAL_USER" rm -rf "$temp_dir"
                log "INFO" "Ukiyo-e backgrounds installed to $wallpaper_dir"
            else
                error_exit "Failed to download ukiyo-e backgrounds from SCFUCHS87"
            fi
            ;;
        4)
            log "INFO" "Skipping wallpaper setup"
            log "INFO" "You can manually add wallpapers to $wallpaper_dir"
            ;;
        *)
            log "WARN" "Invalid choice. Skipping wallpaper setup"
            ;;
    esac
    
    # Set initial wallpaper if wallpaper script is available
    set_initial_wallpaper "$wallpaper_dir"
}

# Set initial wallpaper
set_initial_wallpaper() {
    local wallpaper_dir="$1"
    
    log "INFO" "Setting initial wallpaper..."
    
    # Check if wallpaper script is available in /usr/bin/
    if [[ -x "/usr/bin/set_wallpaper_resolution.sh" ]]; then
        log "INFO" "Using resolution-aware wallpaper script..."
        if sudo -u "$REAL_USER" DISPLAY=:0 /usr/bin/set_wallpaper_resolution.sh --print-only 2>/dev/null; then
            log "INFO" "Wallpaper script executed successfully"
        else
            log "WARN" "Wallpaper script execution failed, using fallback"
            set_fallback_wallpaper "$wallpaper_dir"
        fi
    else
        log "INFO" "Wallpaper script not found, using fallback method"
        set_fallback_wallpaper "$wallpaper_dir"
    fi
}

# Set fallback wallpaper
set_fallback_wallpaper() {
    local wallpaper_dir="$1"
    
    # Find a random wallpaper
    local selected_wallpaper
    selected_wallpaper=$(find "$wallpaper_dir" -type f \( -iname '*.jpg' -o -iname '*.png' \) 2>/dev/null | shuf -n 1)
    
    if [[ -n "$selected_wallpaper" ]]; then
        log "INFO" "Setting fallback wallpaper: $(basename "$selected_wallpaper")"
        if command_exists feh; then
            sudo -u "$REAL_USER" bash -c "export DISPLAY=:0; feh --bg-scale '$selected_wallpaper'" 2>/dev/null || log "WARN" "Failed to set wallpaper with feh"
        else
            log "WARN" "feh not available for setting wallpaper"
        fi
    else
        log "WARN" "No wallpaper files found in $wallpaper_dir"
    fi
}

# Update font cache
update_fonts() {
    log "INFO" "Updating font cache..."
    if fc-cache -fv 2>/dev/null; then
        log "INFO" "Font cache updated successfully"
    else
        log "WARN" "Failed to update font cache, continuing..."
    fi
}

# Main installation function
complete_installation() {
    log "INFO" "Completing installation steps..."
}
    
    # Build and install components
    local components=("dwm" "slstatus" "st" "dmenu")
    for component in "${components[@]}"; do
        build_component "$component"
    done
    
    # Install scripts
    install_scripts
    
    # Setup systemd services
    setup_systemd_services
    
    # Setup user configuration
    setup_user_config
    
    # Install desktop entry
    install_desktop_entry
    
    # Setup display manager
    setup_display_manager
    
    # Setup wallpapers
    setup_wallpapers
    
    # Update fonts
    update_fonts
    
    log "INFO" "Installation completed successfully!"
    log "INFO" "You can now log out and select DWM from your display manager"
    log "INFO" "Or use 'startx' if no display manager was installed"
}

# Main function
main() {
    log "INFO" "=== DWM Installation Started ==="
    
    # Pre-installation checks
    check_dependencies
    validate_repository
    
    # System installation
