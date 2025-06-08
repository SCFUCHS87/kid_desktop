#!/bin/bash

# Define wallpaper directory
WALLPAPER_DIR="/home/$USER/Pictures/wallpapers/"

# Find a random wallpaper recursively
WALLPAPER=$(find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)

# Set wallpaper using feh
feh --bg-fill "$WALLPAPER"

# Generate dynamic theme with wpg
wpg -s "$WALLPAPER"

# Update tint2 colors to match

/usr/bin/update-tint2-colors.sh
