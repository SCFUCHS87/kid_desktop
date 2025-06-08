#!/usr/bin/env bash

# Enhanced DWM startup script with error handling and robustness improvements

### UTILITY FUNCTIONS ###
log_error() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" | tee -a "$LOG_FILE" >&2
}

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] INFO: $1" | tee -a "$LOG_FILE"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "Required command '$1' not found"
        return 1
    fi
    return 0
}

wait_for_service() {
    local service_name="$1"
    local max_wait="${2:-10}"
    local count=0
    
    while [ $count -lt $max_wait ]; do
        if pgrep -x "$service_name" > /dev/null; then
            log_info "$service_name started successfully"
            return 0
        fi
        sleep 1
        ((count++))
    done
    
    log_error "$service_name failed to start within ${max_wait} seconds"
    return 1
}

### SETUP ###
# Create log directory and file
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
LOG_FILE="$LOG_DIR/dwm-startup.log"
mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

log_info "Starting DWM startup script"

### EXIT IF DWM IS ALREADY RUNNING ###
if pgrep -x dwm > /dev/null; then
    log_info "DWM already running — skipping dwm-startup.sh"
    exit 0
fi

### ENVIRONMENT SETUP ###
export DISPLAY="${DISPLAY:-:0}"
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=dwm
export XDG_SESSION_DESKTOP=dwm
export GDK_BACKEND=x11

log_info "Environment variables set"

### VERIFY REQUIRED COMMANDS ###
REQUIRED_COMMANDS=("dwm" "xhost")
OPTIONAL_COMMANDS=("dunst" "gnome-keyring-daemon" "tint2" "dunst" "picom" "slstatus" "volumeicon")

for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! check_command "$cmd"; then
        log_error "Critical command missing: $cmd"
        exit 1
    fi
done

log_info "Required commands verified"

### GRANT X ACCESS FOR ROOT ###
if ! xhost +si:localuser:root &> /dev/null; then
    log_error "Failed to grant X access for root user"
else
    log_info "X access granted for root user"
fi

### START GNOME KEYRING + ONLINE ACCOUNTS ###
if check_command "gnome-keyring-daemon"; then
    if eval "$(gnome-keyring-daemon --start --components=pkcs11,secrets,ssh,gpg)"; then
        export SSH_AUTH_SOCK
        log_info "GNOME keyring daemon started"
    else
        log_error "Failed to start GNOME keyring daemon"
    fi
fi

# Start GNOME Online Accounts services (with fallback paths)
GOA_DAEMON_PATHS=("/usr/libexec/goa-daemon" "/usr/lib/goa-daemon" "/usr/local/libexec/goa-daemon")
GOA_IDENTITY_PATHS=("/usr/libexec/goa-identity-service" "/usr/lib/goa-identity-service" "/usr/local/libexec/goa-identity-service")
AT_SPI_PATHS=("/usr/libexec/at-spi-bus-launcher" "/usr/lib/at-spi-bus-launcher" "/usr/local/libexec/at-spi-bus-launcher")

for path in "${GOA_DAEMON_PATHS[@]}"; do
    if [ -x "$path" ]; then
        "$path" & disown
        log_info "Started goa-daemon from $path"
        break
    fi
done

for path in "${GOA_IDENTITY_PATHS[@]}"; do
    if [ -x "$path" ]; then
        "$path" & disown
        log_info "Started goa-identity-service from $path"
        break
    fi
done

for path in "${AT_SPI_PATHS[@]}"; do
    if [ -x "$path" ]; then
        "$path" & disown
        log_info "Started at-spi-bus-launcher from $path"
        break
    fi
done

### DESKTOP SETTINGS SUPPORT ###
# Try different settings daemons in order of preference: lxsession -> gnome-settings-daemon -> xsettingsd
if check_command "lxsession"; then
    lxsession & disown
    log_info "Started lxsession"
    # Wait for XSETTINGS to initialize
    sleep 3
elif check_command "gnome-settings-daemon"; then
    gnome-settings-daemon & disown
    log_info "Started gnome-settings-daemon"
    sleep 2
elif check_command "xsettingsd"; then
    xsettingsd & disown
    log_info "Started xsettingsd"
    sleep 2
else
    log_info "No settings daemon found - continuing without XSETTINGS support"
fi

### TINT2 PANEL WITH RESTART LOOP ###
if check_command "tint2"; then
    (while true; do
        G_SLICE=always-malloc tint2
        exit_code=$?
        if [ $exit_code -ne 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] tint2 crashed with exit code $exit_code, restarting..." >> "$LOG_FILE"
        fi
        sleep 1
    done) &
    
    # Wait for tint2's tray to initialize with timeout
    log_info "Waiting for tint2 to initialize..."
    if wait_for_service "tint2" 10; then
        log_info "tint2 panel started successfully"
    else
        log_error "tint2 failed to start properly"
    fi
else
    log_info "tint2 not found - skipping panel startup"
fi

### BACKGROUND UTILITIES ###
BACKGROUND_SERVICES=("dunst" "picom" "slstatus" "volumeicon")

for service in "${BACKGROUND_SERVICES[@]}"; do
    if check_command "$service"; then
        "$service" & disown
        log_info "Started $service"
    else
        log_info "$service not found - skipping"
    fi
done

# Start wpg-feh-random.sh if it exists
if check_command "wpg-feh-random.sh"; then
    wpg-feh-random.sh & disown
    log_info "Started wpg-feh-random.sh"
else
    log_info "wpg-feh-random.sh not found - skipping wallpaper randomization"
fi

### FINAL SETUP AND DWM LAUNCH ###
log_info "All services started, launching DWM"

# Small delay to ensure all services are settled
sleep 1

### START DWM ###
exec dwm
