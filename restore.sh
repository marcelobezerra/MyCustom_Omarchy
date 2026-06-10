#!/bin/bash
# restore.sh — Restaura o ambiente MyCustom_Omarchy após reinstalação do Omarchy
# Pré-requisito: Omarchy instalado e primeiro boot concluído.

set -e

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
info() { echo -e "${BLUE}[..]${NC} $1"; }
warn() { echo -e "${YELLOW}[!!]${NC} $1"; }
err()  { echo -e "${RED}[ERRO]${NC} $1"; exit 1; }
header() { echo -e "\n${BOLD}------------------------------------------------------${NC}\n${BOLD}  $1${NC}\n${BOLD}------------------------------------------------------${NC}"; }

echo ""
echo -e "${BOLD}======================================================"
echo -e "  MyCustom_Omarchy — Restauração do ambiente"
echo -e "======================================================${NC}"
echo ""

# ---------------------------------------------------------------------------
# Verificações iniciais
# ---------------------------------------------------------------------------
header "VERIFICAÇÕES INICIAIS"

command -v yay  &>/dev/null || err "yay não encontrado. Instale o yay antes de continuar."
command -v git  &>/dev/null || err "git não encontrado."
command -v gcc  &>/dev/null || warn "gcc não encontrado — será instalado."

# ---------------------------------------------------------------------------
# Autenticação sudo (mantém viva durante todo o script)
# ---------------------------------------------------------------------------
header "AUTENTICAÇÃO SUDO"

info "Solicitando senha sudo..."
sudo -v || err "Falha na autenticação sudo."
( while true; do sudo -n true; sleep 50; kill -0 "$$" || exit; done 2>/dev/null ) &
SUDO_KEEPALIVE_PID=$!
trap "kill $SUDO_KEEPALIVE_PID 2>/dev/null" EXIT
log "Sudo autenticado."

# ---------------------------------------------------------------------------
# Instalação de pacotes
# ---------------------------------------------------------------------------
header "PACOTES — REPOSITÓRIOS OFICIAIS (pacman)"

PACMAN_PKGS=(
    android-tools       # adb — WiVRn USB tethering
    jq                  # weather.sh e hook Claude
    gcc                 # compilar wivrn_ipv4_shim.c
    openrgb             # iluminação RGB
    github-cli          # gh — download de APKs do WiVRn
)

info "Instalando com pacman..."
sudo pacman -S --needed --noconfirm "${PACMAN_PKGS[@]}"
log "Pacotes pacman instalados."

header "PACOTES — AUR (yay)"

AUR_PKGS=(
    snixembed           # tray icons AppIndicator/StatusNotifierItem
    wivrn-full-git      # servidor WiVRn com fixes NVIDIA encoder
    opencomposite-git   # substituto do SteamVR (instala em /opt/opencomposite)
    neo-matrix-git      # chuva digital estilo Matrix com katakana
    protonup-qt         # gerenciador de versões do Proton
)

info "Instalando com yay (pode demorar na compilação do WiVRn)..."
yay -S --needed --noconfirm "${AUR_PKGS[@]}"
log "Pacotes AUR instalados."

header "PROTON CACHYOS"

if pacman -Q proton-cachyos &>/dev/null; then
    log "proton-cachyos já instalado."
else
    info "Instalando proton-cachyos..."
    sudo pacman -S --needed --noconfirm proton-cachyos 2>/dev/null || \
        yay -S --needed --noconfirm proton-cachyos 2>/dev/null || \
        warn "proton-cachyos não encontrado — instale manualmente via ProtonUp-Qt."
fi

# ---------------------------------------------------------------------------
# Compilar shim IPv4 para WiVRn
# ---------------------------------------------------------------------------
header "COMPILAÇÃO — SHIM IPv4 (WiVRn)"

mkdir -p ~/.local/lib
info "Compilando wivrn_ipv4_shim.so..."
gcc -shared -fPIC -O2 \
    -o ~/.local/lib/wivrn_ipv4_shim.so \
    "$REPO_DIR/wivrn/wivrn_ipv4_shim.c" -ldl
log "Shim compilado em ~/.local/lib/wivrn_ipv4_shim.so"

# ---------------------------------------------------------------------------
# Cópia dos arquivos de configuração
# ---------------------------------------------------------------------------
header "CONFIGS — HYPRLAND"

mkdir -p ~/.config/hypr
cp "$REPO_DIR/hypr/"* ~/.config/hypr/
chmod +x \
    ~/.config/hypr/fix-audio.sh \
    ~/.config/hypr/screensaver-start.sh \
    ~/.config/hypr/screensaver-stop.sh
log "~/.config/hypr/"

header "CONFIGS — WAYBAR"

mkdir -p ~/.config/waybar
cp "$REPO_DIR/waybar/"* ~/.config/waybar/
chmod +x \
    ~/.config/waybar/netspeed.sh \
    ~/.config/waybar/network-info.sh \
    ~/.config/waybar/weather.sh
log "~/.config/waybar/"

header "CONFIGS — WIVRN"

mkdir -p ~/.config/wivrn
cp "$REPO_DIR/wivrn/config.json" ~/.config/wivrn/
log "~/.config/wivrn/config.json"

mkdir -p ~/.config/systemd/user/wivrn.service.d
cp "$REPO_DIR/wivrn/systemd/"* ~/.config/systemd/user/wivrn.service.d/
log "~/.config/systemd/user/wivrn.service.d/"

mkdir -p ~/.config/openxr/1
cp "$REPO_DIR/wivrn/openxr/active_runtime.json" ~/.config/openxr/1/
log "~/.config/openxr/1/active_runtime.json"

mkdir -p ~/.config/openvr
cp "$REPO_DIR/wivrn/openvr/openvrpaths.vrpath" ~/.config/openvr/
chmod 444 ~/.config/openvr/openvrpaths.vrpath
log "~/.config/openvr/openvrpaths.vrpath (chmod 444)"

mkdir -p ~/.local/bin
cp "$REPO_DIR/wivrn/wivrn-start" ~/.local/bin/
cp "$REPO_DIR/wivrn/wivrn-stop"  ~/.local/bin/
chmod +x ~/.local/bin/wivrn-start ~/.local/bin/wivrn-stop
log "~/.local/bin/wivrn-start e wivrn-stop"

header "CONFIGS — OMARCHY BRANDING"

mkdir -p ~/.config/omarchy/branding
cp "$REPO_DIR/omarchy/screensaver.txt" ~/.config/omarchy/branding/
log "~/.config/omarchy/branding/screensaver.txt"

# ---------------------------------------------------------------------------
# Arquivos de sistema
# ---------------------------------------------------------------------------
header "SISTEMA — REDE WIVRN (RNDIS)"

sudo cp "$REPO_DIR/wivrn/network/10-wivrn-rndis.network" /etc/systemd/network/
log "/etc/systemd/network/10-wivrn-rndis.network"

header "SISTEMA — IPv6 DISABLE (sysctl)"

sudo cp "$REPO_DIR/system/40-ipv6.conf" /etc/sysctl.d/40-ipv6.conf
log "/etc/sysctl.d/40-ipv6.conf"

header "SISTEMA — PARÂMETROS DO KERNEL (limine)"

CUSTOM_CMDLINE="quiet splash mitigations=off ipv6.disable=1 acpi_enforce_resources=lax loglevel=0 systemd.show_status=false rd.udev.log_level=0 vt.global_cursor_default=0"
LIMINE_FILE="/etc/default/limine"

if grep -q "mitigations=off" "$LIMINE_FILE" 2>/dev/null; then
    log "Parâmetros customizados já presentes em $LIMINE_FILE — pulando."
else
    info "Injetando parâmetros customizados em $LIMINE_FILE..."
    # Adiciona antes da última linha KERNEL_CMDLINE vazia
    sudo sed -i "/^KERNEL_CMDLINE\[default\]+=\"\"$/i KERNEL_CMDLINE[default]+=\" $CUSTOM_CMDLINE\"" "$LIMINE_FILE"
    log "Parâmetros injetados."
fi

# ---------------------------------------------------------------------------
# Recarregar serviços
# ---------------------------------------------------------------------------
header "RECARREGANDO SERVIÇOS"

info "systemctl daemon-reload (user)..."
systemctl --user daemon-reload

info "systemctl daemon-reload (system)..."
sudo systemctl daemon-reload

info "Aplicando sysctl..."
sudo sysctl -p /etc/sysctl.d/40-ipv6.conf

info "Regenerando entradas do bootloader (limine-entry-tool)..."
sudo limine-entry-tool

info "Habilitando serviço WiVRn..."
systemctl --user enable wivrn.service

log "Serviços recarregados."

# ---------------------------------------------------------------------------
# Resumo final
# ---------------------------------------------------------------------------
echo ""
echo -e "${BOLD}======================================================"
echo -e "  Restauração concluída!"
echo -e "======================================================${NC}"
echo ""
echo -e "${YELLOW}Pendências manuais (não automatizáveis):${NC}"
echo ""
echo "  1. REINICIAR o sistema para aplicar ipv6.disable=1 e demais"
echo "     parâmetros do kernel via limine."
echo ""
echo "  2. WiVRn APK no Pico 4:"
echo "     gh run download <run-id> -R WiVRn/WiVRn -n apk-Release"
echo "     (obtenha o run-id em: https://github.com/WiVRn/WiVRn/actions)"
echo ""
echo "  3. Proton CachyOS: confirme a versão instalada no ProtonUp-Qt"
echo "     e selecione 'proton-cachyos-11' nas propriedades do HL:A na Steam."
echo ""
echo "  4. OpenRGB: importe o perfil 'RED' manualmente na primeira execução."
echo ""
echo "  5. Snapper já desativado pelas configs — verifique se o pacote"
echo "     foi removido: sudo pacman -Rns snapper limine-snapper-sync"
echo ""
