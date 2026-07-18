#!/usr/bin/env bash

# Reload udev rules
if command -v udevadm &> /dev/null; then
    echo "Reloading udev rules..."
    udevadm control --reload-rules
    udevadm trigger --subsystem-match=backlight
fi

# Ensure the script is executable
chmod +x "$0"