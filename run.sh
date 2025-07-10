#!/bin/bash

# Give the launcher permission

xattr -rd com.apple.quarantine Challenge2025-Launcher.app

# Run the Launcher

./Challenge2025-Launcher.app/Contents/MacOS/Challenge2025-Launcher

