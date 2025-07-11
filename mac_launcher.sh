#!/bin/bash

# Determine the directory of the running launcher script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Change working directory to the script's directory
cd "$SCRIPT_DIR"

# Use path relative to the script's location
APP_PATH="$SCRIPT_DIR/.hiddenapp/Challenge2025_Launcher_macos.app"
EXEC_PATH="$APP_PATH/Contents/MacOS/Challenge2025-Launcher"

# 1. Remove quarantine attribute
xattr -rd com.apple.quarantine "$APP_PATH" 2>/dev/null || true

# 2. Run the actual binary
"$EXEC_PATH"
