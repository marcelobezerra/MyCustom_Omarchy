#!/bin/bash
# /usr/local/bin/update-pacotes-hook.sh
# Chamado pelo pacman após instalação de pacotes.
# Detecta pacotes da última transação via log, filtra explícitos e atualiza pacotes.txt.

PACOTES_FILE="/home/richthofen/pacotes.txt"
REPO_URL="https://github.com/marcelobezerra/MyCustom_Omarchy.git"
REPO_DIR="/home/richthofen/MyCustom_Omarchy_repo"
REPO_USER="richthofen"
TODAY=$(date +%Y-%m-%d)
LOG="/var/log/pacman.log"

run_as_user() {
    su -s /bin/bash "$REPO_USER" -c "$1" 2>/dev/null
}

# Linha do início da última transação no log do pacman
last_tx_line=$(grep -n "\[ALPM\] transaction started" "$LOG" | tail -1 | cut -d: -f1)
[ -z "$last_tx_line" ] && exit 0

# Filtra pacotes instalados nessa transação que sejam explícitos e ainda não listados
NEW_PKGS=()
while IFS= read -r pkg; do
    [[ -z "$pkg" ]] && continue
    reason=$(pacman -Qi "$pkg" 2>/dev/null | awk -F': ' '/Install Reason/{gsub(/^[[:space:]]+/,"",$2); print $2}')
    [[ "$reason" != "Explicitly installed" ]] && continue
    grep -qxF "$pkg" "$PACOTES_FILE" 2>/dev/null || NEW_PKGS+=("$pkg")
done < <(tail -n +"$last_tx_line" "$LOG" | grep "\[ALPM\] installed" | awk '{print $4}')

[[ ${#NEW_PKGS[@]} -eq 0 ]] && exit 0

# Garante que pacotes.txt existe
if [ ! -f "$PACOTES_FILE" ]; then
    touch "$PACOTES_FILE"
    chown "$REPO_USER:$REPO_USER" "$PACOTES_FILE"
fi

# Adiciona seção de data se ainda não existe
grep -q "^# --- ${TODAY}" "$PACOTES_FILE" 2>/dev/null || printf '\n# --- %s ---\n\n' "$TODAY" >> "$PACOTES_FILE"

# Adiciona os pacotes novos
for pkg in "${NEW_PKGS[@]}"; do
    echo "$pkg" >> "$PACOTES_FILE"
done

# Garante que o repo existe
if [ ! -d "$REPO_DIR/.git" ]; then
    run_as_user "git clone '$REPO_URL' '$REPO_DIR' && git -C '$REPO_DIR' config user.email 'bezerrasilva.marcelo@gmail.com' && git -C '$REPO_DIR' config user.name 'marcelobezerra'" || exit 0
fi

# Copia e faz push para o GitHub
PKG_LIST=$(printf '%s, ' "${NEW_PKGS[@]}"); PKG_LIST="${PKG_LIST%, }"
cp "$PACOTES_FILE" "$REPO_DIR/pacotes.txt"
run_as_user "cd '$REPO_DIR' && git add pacotes.txt && git diff --cached --quiet || (git commit -m 'pacotes.txt: adiciona $PKG_LIST [$TODAY]' && git push)"
