#!/bin/bash
pidof hyprlock && exit 0
date +%s > /tmp/screensaver-started.ts
omarchy-launch-screensaver

# Turn off monitors 45 minutes after screensaver starts (total 60 min of idle)
(sleep 2700 && hyprctl dispatch dpms off) &
echo $! > /tmp/screensaver-dpms-timer.pid
