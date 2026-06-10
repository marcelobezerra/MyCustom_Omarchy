#!/bin/bash
sleep 3

# Set HDMI (LG ULTRAWIDE) as default audio output
HDMI_SINK=$(pactl list sinks short | awk '/hdmi/ {print $2; exit}')
if [ -n "$HDMI_SINK" ]; then
    pactl set-default-sink "$HDMI_SINK"
fi

# Keep analog card at full volume for headphone use
amixer -c 1 sset Headphone 100% unmute
amixer -c 1 sset 'Auto-Mute Mode' Disabled
amixer -c 1 sset Master 100% unmute
