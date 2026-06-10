#!/bin/bash
# Kill screensaver
pkill -f org.omarchy.screensaver 2>/dev/null

# Cancel the background monitor-off timer
if [ -f /tmp/screensaver-dpms-timer.pid ]; then
    kill "$(cat /tmp/screensaver-dpms-timer.pid)" 2>/dev/null
    rm -f /tmp/screensaver-dpms-timer.pid
fi

# Ensure monitors are on
hyprctl dispatch dpms on
