#!/bin/bash

GODOT_LAUNCHER_NAME="Challenge2025_Launcher_macos.app"

# Get version number from command line argument
if [ $# -eq 0 ]; then
    echo "Usage: $0 <version_number>"
    exit 1
fi

VERSION=$1
echo "Building version: $VERSION"

# Check if Challenge2025-Launcher.app exists
echo "Checking for $GODOT_LAUNCHER_NAME..."
if [ ! -d "$GODOT_LAUNCHER_NAME" ]; then
    echo "Error: $GODOT_LAUNCHER_NAME not found"
    exit 1
fi

# Remove existing build directory if it exists
echo "Removing existing build directory if it exists..."
if [ -d "Challenge2025-Launcher" ]; then
    rm -rf Challenge2025-Launcher
fi

# Remove existing zip file if it exists
echo "Removing existing zip file if it exists..."
if [ -f "${VERSION}Challenge2025_Launcher_macos.zip" ]; then
    rm "${VERSION}Challenge2025_Launcher_macos.zip"
fi

# Make directory for the build
echo "Creating build directory..."
mkdir -p Challenge2025-Launcher
mkdir -p Challenge2025-Launcher/Applications

# Copy the launcher to the build directory
echo "Copying $GODOT_LAUNCHER_NAME to build directory..."
cp -r "$GODOT_LAUNCHER_NAME" Challenge2025-Launcher/Applications/

# Compile the Swift launcher
echo "Compiling Swift launcher..."
swiftc mac_launcher.swift -o Challenge2025-MacLauncher

# Copy the run script to the build directory
echo "Copying Swift launcher to build directory..."
cp Challenge2025-MacLauncher Challenge2025-Launcher/

# Create the zip file
echo "Creating zip file..."
zip -r "${VERSION}Challenge2025_Launcher_macos.zip" Challenge2025-Launcher