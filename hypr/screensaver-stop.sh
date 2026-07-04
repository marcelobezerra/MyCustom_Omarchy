#!/bin/bash

# Cancela o timer de DPMS sempre — independente do período de graça
if [ -f /tmp/screensaver-dpms-timer.pid ]; then
    kill "$(cat /tmp/screensaver-dpms-timer.pid)" 2>/dev/null
    rm -f /tmp/screensaver-dpms-timer.pid
fi

# Ignora on-resume espúrio causado pelo próprio lançamento do screensaver (hyprctl dispatch exec
# reseta o idle timer internamente ao abrir o Alacritty e mudar o foco de janela)
if [ -f /tmp/screensaver-started.ts ]; then
    started=$(cat /tmp/screensaver-started.ts)
    now=$(date +%s)
    diff=$((now - started))
    if [ "$diff" -lt 5 ]; then
        exit 0
    fi
fi

# Kill screensaver
pkill -f org.omarchy.screensaver 2>/dev/null

# Ensure monitors are on
hyprctl dispatch dpms on
