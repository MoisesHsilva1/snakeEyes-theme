#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  🐍 snakeEyes-theme — install.sh
#  CachyOS / Arch Linux
#  Autor: MoisesHsilva1
#  Repo:  https://github.com/MoisesHsilva1/snakeEyes-theme
# ═══════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
BOLD='\033[1m'
NC='\033[0m'

log()     { echo -e "${GREEN}[✓]${NC} $1"; }
warn()    { echo -e "${YELLOW}[!]${NC} $1"; }
info()    { echo -e "${BLUE}[→]${NC} $1"; }
err()     { echo -e "${RED}[✗]${NC} $1"; exit 1; }
section() { echo -e "\n${BOLD}$1${NC}"; echo "────────────────────────────────────────"; }

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── Banner ───────────────────────────────────────────────────────
echo -e "
${GREEN}
  ███████╗███╗   ██╗ █████╗ ██╗  ██╗███████╗    ███████╗██╗   ██╗███████╗███████╗
  ██╔════╝████╗  ██║██╔══██╗██║ ██╔╝██╔════╝    ██╔════╝╚██╗ ██╔╝██╔════╝██╔════╝
  ███████╗██╔██╗ ██║███████║█████╔╝ █████╗      █████╗   ╚████╔╝ █████╗  ███████╗
  ╚════██║██║╚██╗██║██╔══██║██╔═██╗ ██╔══╝      ██╔══╝    ╚██╔╝  ██╔══╝  ╚════██║
  ███████║██║ ╚████║██║  ██║██║  ██╗███████╗    ███████╗   ██║   ███████╗███████║
  ╚══════╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝  ╚═╝╚══════╝    ╚══════╝   ╚═╝   ╚══════╝╚══════╝
${NC}
  ${BOLD}Repositório:${NC} $REPO_DIR
  ${BOLD}Sistema:${NC}     CachyOS / Arch Linux
"

section "0. Verificações iniciais"

[[ "$EUID" -eq 0 ]] && err "Não rode como root. O script pede sudo quando necessário."

if ! ping -c 1 archlinux.org &>/dev/null; then
  err "Sem conexão com a internet. Verifique sua rede."
fi
log "Conexão com internet OK"

section "1. Atualizando sistema"
sudo pacman -Syu --noconfirm
log "Sistema atualizado"

section "2. Instalando dependências base"
sudo pacman -S --needed --noconfirm git base-devel curl wget
log "Dependências base instaladas"

section "3. Instalando pacotes do pacman"

if [[ -f "$REPO_DIR/pkg/pacman-list.txt" ]]; then
  TOTAL=$(wc -l < "$REPO_DIR/pkg/pacman-list.txt")
  info "Instalando $TOTAL pacotes do pacman..."
  sudo pacman -S --needed --noconfirm - < "$REPO_DIR/pkg/pacman-list.txt" \
    && log "Pacotes do pacman instalados" \
    || warn "Alguns pacotes falharam — pode ser nome diferente no repositório atual"
else
  warn "pkg/pacman-list.txt não encontrado, pulando..."
fi

section "4. AUR Helper (yay)"

if command -v yay &>/dev/null; then
  log "yay já instalado: $(yay --version | head -1)"
else
  info "Instalando yay..."
  git clone https://aur.archlinux.org/yay.git /tmp/yay-build
  (cd /tmp/yay-build && makepkg -si --noconfirm)
  rm -rf /tmp/yay-build
  log "yay instalado com sucesso"
fi

section "5. Instalando pacotes do AUR"

if [[ -f "$REPO_DIR/pkg/aur-list.txt" ]]; then
  TOTAL=$(wc -l < "$REPO_DIR/pkg/aur-list.txt")
  info "Instalando $TOTAL pacotes do AUR..."
  yay -S --needed --noconfirm - < "$REPO_DIR/pkg/aur-list.txt" \
    && log "Pacotes do AUR instalados" \
    || warn "Alguns pacotes do AUR falharam — verifique manualmente"
else
  warn "pkg/aur-list.txt não encontrado, pulando..."
fi

section "6. Aplicando dotfiles"

apply_dotfile() {
  local src="$1"
  local dst="$2"
  local name
  name="$(basename "$dst")"

  if [[ ! -e "$src" ]]; then
    warn "  Origem não encontrada, pulando: $src"
    return
  fi

  if [[ -e "$dst" && ! -L "$dst" ]]; then
    warn "  Backup criado: $dst.bak"
    mv "$dst" "$dst.bak"
  elif [[ -L "$dst" ]]; then
    rm "$dst"
  fi

  mkdir -p "$(dirname "$dst")"
  ln -sf "$src" "$dst"
  log "  $name → $dst"
}

apply_dotfile "$REPO_DIR/dotfiles/kitty"    "$HOME/.config/kitty"

[[ -d "$REPO_DIR/dotfiles/nvim" ]] && \
  apply_dotfile "$REPO_DIR/dotfiles/nvim"   "$HOME/.config/nvim"

[[ -f "$REPO_DIR/dotfiles/.zshrc" ]] && \
  apply_dotfile "$REPO_DIR/dotfiles/.zshrc" "$HOME/.zshrc"

# apply_dotfile "$REPO_DIR/dotfiles/hypr"   "$HOME/.config/hypr"
# apply_dotfile "$REPO_DIR/dotfiles/waybar" "$HOME/.config/waybar"
# apply_dotfile "$REPO_DIR/dotfiles/rofi"   "$HOME/.config/rofi"

section "7. Instalando temas visuais"

mkdir -p ~/.themes ~/.icons ~/.local/share/fonts ~/.config/gtk-3.0

if [[ -d "$REPO_DIR/themes/Bibata-Modern-Ice" ]]; then
  cp -r "$REPO_DIR/themes/Bibata-Modern-Ice" ~/.icons/
  log "  Cursor Bibata-Modern-Ice copiado"
fi

# Outros temas do repo
[[ -d "$REPO_DIR/themes/.themes" ]] && \
  cp -r "$REPO_DIR/themes/.themes/"* ~/.themes/ 2>/dev/null && log "  Temas GTK copiados"

[[ -d "$REPO_DIR/themes/.icons" ]] && \
  cp -r "$REPO_DIR/themes/.icons/"* ~/.icons/ 2>/dev/null && log "  Ícones copiados"

[[ -d "$REPO_DIR/themes/fonts" ]] && \
  cp -r "$REPO_DIR/themes/fonts/"* ~/.local/share/fonts/ 2>/dev/null && log "  Fontes copiadas"

fc-cache -fv > /dev/null
log "  Cache de fontes atualizado"

section "8. Aplicando tema ativo (settings.ini)"

SETTINGS="$REPO_DIR/themes/settings.ini"

if [[ -f "$SETTINGS" ]]; then
  GTK_THEME=$(grep    'gtk-theme-name'        "$SETTINGS" | cut -d= -f2 | xargs)
  ICON_THEME=$(grep   'gtk-icon-theme-name'   "$SETTINGS" | cut -d= -f2 | xargs)
  CURSOR_THEME=$(grep 'gtk-cursor-theme-name' "$SETTINGS" | cut -d= -f2 | xargs)
  CURSOR_SIZE=$(grep  'gtk-cursor-theme-size' "$SETTINGS" | cut -d= -f2 | xargs)
  FONT=$(grep         'gtk-font-name'         "$SETTINGS" | cut -d= -f2 | xargs)
  DARK=$(grep         'gtk-application-prefer-dark-theme' "$SETTINGS" | cut -d= -f2 | xargs)
  SOUND=$(grep        'gtk-sound-theme-name'  "$SETTINGS" | cut -d= -f2 | xargs)
  DPI=$(grep          'gtk-xft-dpi'           "$SETTINGS" | cut -d= -f2 | xargs)

  if command -v gsettings &>/dev/null; then
    [[ -n "$GTK_THEME" ]]    && gsettings set org.gnome.desktop.interface gtk-theme       "$GTK_THEME"
    [[ -n "$ICON_THEME" ]]   && gsettings set org.gnome.desktop.interface icon-theme      "$ICON_THEME"
    [[ -n "$CURSOR_THEME" ]] && gsettings set org.gnome.desktop.interface cursor-theme    "$CURSOR_THEME"
    [[ -n "$CURSOR_SIZE" ]]  && gsettings set org.gnome.desktop.interface cursor-size     "$CURSOR_SIZE"
    [[ -n "$FONT" ]]         && gsettings set org.gnome.desktop.interface font-name       "$FONT"
    [[ "$DARK" == "true" ]]  && gsettings set org.gnome.desktop.interface color-scheme    'prefer-dark'
    [[ -n "$SOUND" ]]        && gsettings set org.gnome.desktop.sound theme-name          "$SOUND"
  fi

  cp "$SETTINGS" ~/.config/gtk-3.0/settings.ini
  [[ -d ~/.config/gtk-4.0 ]] && cp "$SETTINGS" ~/.config/gtk-4.0/settings.ini

  log "  Tema:   ${GTK_THEME:-não definido}"
  log "  Ícones: ${ICON_THEME:-não definido}"
  log "  Cursor: ${CURSOR_THEME:-não definido} (${CURSOR_SIZE}px)"
  log "  Fonte:  ${FONT:-não definida}"
  log "  Dark mode: ${DARK:-false}"
  log "  Settings.ini copiado para gtk-3.0 e gtk-4.0"
else
  warn "themes/settings.ini não encontrado, pulando tema..."
fi

section "9. Configurando wallpaper"

WALL_DIR=""
[[ -d "$REPO_DIR/wallpapers" ]] && WALL_DIR="$REPO_DIR/wallpapers"
[[ -d "$REPO_DIR/walpapers"  ]] && WALL_DIR="$REPO_DIR/walpapers"

if [[ -n "$WALL_DIR" ]]; then
  WALLPAPER=$(find "$WALL_DIR" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | head -1)
  if [[ -n "$WALLPAPER" ]]; then
    # Tenta GNOME, KDE e XFCE
    if command -v gsettings &>/dev/null; then
      gsettings set org.gnome.desktop.background picture-uri       "file://$WALLPAPER" 2>/dev/null || true
      gsettings set org.gnome.desktop.background picture-uri-dark  "file://$WALLPAPER" 2>/dev/null || true
    fi
    if command -v plasma-apply-wallpaperimage &>/dev/null; then
      plasma-apply-wallpaperimage "$WALLPAPER" 2>/dev/null || true
    fi
    log "  Wallpaper: $(basename "$WALLPAPER")"
  fi
else
  info "  Pasta wallpapers não encontrada, pulando..."
fi

section "10. Scripts de pós-instalação"

if [[ -d "$REPO_DIR/scripts/post-install" ]]; then
  for script in "$REPO_DIR/scripts/post-install/"*.sh; do
    if [[ -x "$script" ]]; then
      info "  Executando: $(basename "$script")"
      bash "$script" || warn "  $(basename "$script") falhou, continuando..."
    else
      warn "  $(basename "$script") não é executável (+x), pulando"
    fi
  done
else
  info "  Nenhum script de pós-instalação encontrado"
fi

echo -e "
${GREEN}${BOLD}══════════════════════════════════════════${NC}
${GREEN}${BOLD}  🐍 snakeEyes-theme — setup concluído!  ${NC}
${GREEN}${BOLD}══════════════════════════════════════════${NC}

  ${BOLD}Tema GTK:${NC}    ${GTK_THEME:-Breeze}
  ${BOLD}Ícones:${NC}      ${ICON_THEME:-YAMIS}
  ${BOLD}Cursor:${NC}      ${CURSOR_THEME:-Bibata-Modern-Ice}
  ${BOLD}Dark mode:${NC}   ativado

  ${YELLOW}→ Próximos passos:${NC}
    1. source ~/.zshrc    (recarrega o shell)
    2. Reinicie o sistema para aplicar cursor e DPI
    3. Abra Configurações do sistema para confirmar o tema

  ${BLUE}Repo:${NC} https://github.com/MoisesHsilva1/snakeEyes-theme
"