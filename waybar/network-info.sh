#!/bin/bash

IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '/dev/{for(i=1;i<=NF;i++) if($i=="dev") print $(i+1)}' | head -1)
[ -z "$IFACE" ] && IFACE=$(ls /sys/class/net/ | grep -v lo | head -1)

IP=$(ip addr show "$IFACE" | awk '/inet /{print $2}' | head -1)
ADDR=${IP%/*}
PREFIX=${IP#*/}
GW=$(ip route | awk '/default/{print $3}' | head -1)
DNS=$(resolvectl dns "$IFACE" 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | tr '\n' ' ' | sed 's/ $//')
[ -z "$DNS" ] && DNS="N/D"

MASK=$(python3 -c "p=$PREFIX; m=((0xFFFFFFFF<<(32-p))&0xFFFFFFFF); print('.'.join([str((m>>(8*i))&0xFF) for i in [3,2,1,0]]))" 2>/dev/null)

RX=$(cat /sys/class/net/"$IFACE"/statistics/rx_bytes 2>/dev/null || echo 0)
TX=$(cat /sys/class/net/"$IFACE"/statistics/tx_bytes 2>/dev/null || echo 0)

RX_FMT=$(awk -v b="$RX" 'BEGIN{ if(b>=1073741824) printf "%.2f GB",b/1073741824; else if(b>=1048576) printf "%.2f MB",b/1048576; else if(b>=1024) printf "%.1f KB",b/1024; else printf "%d B",b }')
TX_FMT=$(awk -v b="$TX" 'BEGIN{ if(b>=1073741824) printf "%.2f GB",b/1073741824; else if(b>=1048576) printf "%.2f MB",b/1048576; else if(b>=1024) printf "%.1f KB",b/1024; else printf "%d B",b }')

notify-send -u low -t 8000 "Rede: $IFACE" "IP: $ADDR | Mascara: $MASK (/$PREFIX)
GW: $GW | DNS: $DNS
Download: $RX_FMT | Upload: $TX_FMT"
