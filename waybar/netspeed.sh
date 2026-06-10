#!/bin/bash
IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -1)
[ -z "$IFACE" ] && IFACE=$(ls /sys/class/net/ | grep -v lo | head -1)

TMPFILE="/tmp/waybar-netspeed"
NOW=$(date +%s%N)
RX=$(cat /sys/class/net/$IFACE/statistics/rx_bytes)
TX=$(cat /sys/class/net/$IFACE/statistics/tx_bytes)

fmt() {
    awk -v b=$1 'BEGIN{
        if(b>=1048576) printf "%.1f MB/s", b/1048576
        else if(b>=1024) printf "%.0f KB/s", b/1024
        else printf "%d B/s", b
    }'
}

if [ -f "$TMPFILE" ]; then
    read PT PR PTX < "$TMPFILE"
    MS=$(( (NOW - PT) / 1000000 ))
    [ $MS -gt 0 ] && {
        DL=$(( (RX - PR) * 1000 / MS ))
        UL=$(( (TX - PTX) * 1000 / MS ))
        [ $DL -lt 0 ] && DL=0
        [ $UL -lt 0 ] && UL=0
        echo "↓$(fmt $DL) ↑$(fmt $UL) | "
    }
fi

echo "$NOW $RX $TX" > "$TMPFILE"
