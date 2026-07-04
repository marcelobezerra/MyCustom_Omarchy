#!/bin/bash
# Inicia o screensaver manualmente; ao sair (qualquer tecla/mouse) bloqueia a tela

# Evita múltiplas instâncias
pgrep -f "screensaver-lock.sh" | grep -v $$ > /dev/null && exit 0

omarchy-launch-screensaver force

# Aguarda o screensaver iniciar
sleep 3

# Aguarda o screensaver encerrar
while pgrep -f org.omarchy.screensaver > /dev/null; do
    sleep 1
done

# Bloqueia a tela
omarchy-system-lock
