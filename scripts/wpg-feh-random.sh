#!/bin/bash

# Define wallpaper directory
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

# Optional: path to resolution/HDR-aware script
RESOLUTION_SCRIPT="$HOME/bin/set_wallpaper_resolution.sh"
SELECTED_WALLPAPER=""

# If the resolution/HDR script exists, run it and expect it to export SELECTED_WALLPAPER
if [ -x "$RESOLUTION_SCRIPT" ]; then
    echo "Running resolution-aware wallpaper script..."
    SELECTED_WALLPAPER=$("$RESOLUTION_SCRIPT" --print-only)
fi

# Fallback: if that didn't yield a wallpaper, choose randomly
if [ -z "$SELECTED_WALLPAPER" ]; then
    echo "No preset wallpaper found. Picking random from $WALLPAPER_DIR..."
    SELECTED_WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)
fi

# Set wallpaper using feh
echo "Setting wallpaper: $SELECTED_WALLPAPER"
feh --bg-fill "$SELECTED_WALLPAPER"

# Generate dynamic theme with wpg
wpg -s "$SELECTED_WALLPAPER"

# Optionally update tint2 colors
/usr/bin/update-tint2-colors.sh
