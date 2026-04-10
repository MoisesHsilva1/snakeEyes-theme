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

# Detecta o diretório real do repo — funciona em qualquer caminho
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
log "Repo detectado em: $REPO_DIR"

section "1. Atualizando sistema"
sudo pacman -Syu --noconfirm
log "Sistema atualizado"

section "2. Instalando dependências base"
sudo pacman -S --needed --noconfirm git base-devel curl wget stow
log "Dependências base instaladas"

section "3. Instalando pacotes do pacman"

if [[ -f "$REPO_DIR/pkg/pacman-list.txt" ]]; then
  TOTAL=$(wc -l < "$REPO_DIR/pkg/pacman-list.txt")
  info "Instalando $TOTAL pacotes..."
  sudo pacman -S --needed --noconfirm - < "$REPO_DIR/pkg/pacman-list.txt" \
    && log "Pacotes do pacman instalados" \
    || warn "Alguns pacotes falharam — verifique manualmente"
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
  log "yay instalado"
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

[[ -d "$REPO_DIR/dotfiles/fastfetch/.config/fastfetch" ]] && \
  apply_dotfile "$REPO_DIR/dotfiles/fastfetch/.config/fastfetch" "$HOME/.config/fastfetch" && \
  log "  fastfetch configurado"

if [[ -d "$REPO_DIR/dotfiles/kde" ]]; then
  for kde_file in kglobalshortcutsrc kwinrc kwinrulesrc; do
    [[ -f "$REPO_DIR/dotfiles/kde/$kde_file" ]] && \
      apply_dotfile "$REPO_DIR/dotfiles/kde/$kde_file" "$HOME/.config/$kde_file"
  done
  qdbus org.kde.KWin /KWin reconfigure 2>/dev/null \
    && log "  KWin recarregado" || true
fi

section "7. Instalando temas visuais"

mkdir -p ~/.themes ~/.icons ~/.local/share/fonts ~/.local/share/icons ~/.config/gtk-3.0

if [[ -d "$REPO_DIR/themes/icons/Bibata-Modern-Ice" ]]; then
  cp -r "$REPO_DIR/themes/icons/Bibata-Modern-Ice" ~/.icons/
  log "  Cursor Bibata-Modern-Ice instalado"
fi

for icon_theme in YAMIS klassy klassy-dark; do
  if [[ -d "$REPO_DIR/themes/icons/$icon_theme" ]]; then
    cp -r "$REPO_DIR/themes/icons/$icon_theme" ~/.local/share/icons/
    log "  Ícones $icon_theme instalados"
  fi
done

[[ -d "$REPO_DIR/themes/.themes" ]] && \
  cp -r "$REPO_DIR/themes/.themes/"* ~/.themes/ 2>/dev/null && log "  Temas GTK copiados"

[[ -d "$REPO_DIR/themes/fonts" ]] && \
  cp -r "$REPO_DIR/themes/fonts/"* ~/.local/share/fonts/ 2>/dev/null && log "  Fontes copiadas"

fc-cache -fv > /dev/null
log "  Cache de fontes atualizado"

section "8. Instalando color schemes"

mkdir -p ~/.local/share/color-schemes

if [[ -d "$REPO_DIR/themes/color-schemes" ]]; then
  cp "$REPO_DIR/themes/color-schemes/"*.colors ~/.local/share/color-schemes/
  log "  Color schemes instalados:"
  for f in "$REPO_DIR/themes/color-schemes/"*.colors; do
    log "    → $(basename "$f" .colors)"
  done

  # Aplica SnakeEyes como padrão
  if [[ -f "$REPO_DIR/themes/color-schemes/SnakeEyes.colors" ]]; then
    kwriteconfig5 --file kdeglobals --group General --key ColorScheme "SnakeEyes" 2>/dev/null \
      && log "  Color scheme SnakeEyes aplicado" || true
  fi
else
  warn "  themes/color-schemes/ não encontrado — rode o backup primeiro"
fi

section "9. Aplicando tema ativo (settings.ini)"

SETTINGS="$REPO_DIR/themes/settings.ini"

if [[ -f "$SETTINGS" ]]; then
  GTK_THEME=$(grep    'gtk-theme-name'        "$SETTINGS" | cut -d= -f2 | xargs)
  ICON_THEME=$(grep   'gtk-icon-theme-name'   "$SETTINGS" | cut -d= -f2 | xargs)
  CURSOR_THEME=$(grep 'gtk-cursor-theme-name' "$SETTINGS" | cut -d= -f2 | xargs)
  CURSOR_SIZE=$(grep  'gtk-cursor-theme-size' "$SETTINGS" | cut -d= -f2 | xargs)
  FONT=$(grep         'gtk-font-name'         "$SETTINGS" | cut -d= -f2 | xargs)
  DARK=$(grep         'gtk-application-prefer-dark-theme' "$SETTINGS" | cut -d= -f2 | xargs)

  if command -v plasma-changeicons &>/dev/null; then
    plasma-changeicons YAMIS 2>/dev/null \
      && log "  YAMIS aplicado via plasma-changeicons"
  else
    kwriteconfig5 --file kdeglobals --group Icons --key Theme "YAMIS" 2>/dev/null || true
    log "  YAMIS aplicado via kwriteconfig5"
  fi

  if [[ -n "$CURSOR_THEME" ]]; then
    kwriteconfig5 --file kcminputrc --group Mouse --key cursorTheme "$CURSOR_THEME" 2>/dev/null || true
    kwriteconfig5 --file kcminputrc --group Mouse --key cursorSize   "$CURSOR_SIZE"  2>/dev/null || true
    log "  Cursor $CURSOR_THEME (${CURSOR_SIZE}px) aplicado"
  fi

  cp "$SETTINGS" ~/.config/gtk-3.0/settings.ini
  [[ -d ~/.config/gtk-4.0 ]] && cp "$SETTINGS" ~/.config/gtk-4.0/settings.ini

  log "  Tema GTK: ${GTK_THEME:-não definido}"
  log "  Ícones:   ${ICON_THEME:-não definido}"
  log "  Cursor:   ${CURSOR_THEME:-não definido} (${CURSOR_SIZE}px)"
  log "  Fonte:    ${FONT:-não definida}"
  log "  Dark:     ${DARK:-false}"
else
  warn "themes/settings.ini não encontrado, pulando..."
fi

section "10. Configurando wallpaper"

WALL_DIR=""
[[ -d "$REPO_DIR/wallpapers" ]] && WALL_DIR="$REPO_DIR/wallpapers"
[[ -d "$REPO_DIR/walpapers"  ]] && WALL_DIR="$REPO_DIR/walpapers"  # fallback typo antigo

if [[ -n "$WALL_DIR" ]]; then
  WALLPAPER=$(find "$WALL_DIR" -maxdepth 1 \( -name "*.jpg" -o -name "*.png" -o -name "*.jpeg" \) | head -1)
  if [[ -n "$WALLPAPER" ]]; then
    command -v plasma-apply-wallpaperimage &>/dev/null && \
      plasma-apply-wallpaperimage "$WALLPAPER" 2>/dev/null || true
    log "  Wallpaper: $(basename "$WALLPAPER")"
  fi
else
  info "  Pasta wallpapers não encontrada, pulando..."
fi

section "11. Ativando atalhos Docker"

if [[ -f "$REPO_DIR/scripts/docker/docker.sh" ]]; then
  DOCKER_LINE="source $REPO_DIR/scripts/docker/docker.sh"
  grep -qF "scripts/docker/docker.sh" ~/.zshrc \
    || echo "$DOCKER_LINE" >> ~/.zshrc
  log "  docker.sh ativado no .zshrc"
  log "  Disponível: dockerstart | dockerstop | dockerstatus | dockerrestart"
else
  warn "  scripts/docker/docker.sh não encontrado — crie a pasta e o arquivo primeiro"
fi

section "12. Scripts de pós-instalação"

if [[ -d "$REPO_DIR/scripts/post-install" ]]; then
  for script in "$REPO_DIR/scripts/post-install/"*.sh; do
    if [[ -x "$script" ]]; then
      info "  Executando: $(basename "$script")"
      bash "$script" || warn "  $(basename "$script") falhou, continuando..."
    else
      warn "  $(basename "$script") sem permissão +x, pulando"
    fi
  done
else
  info "  Nenhum script de pós-instalação encontrado"
fi

echo -e "
${GREEN}${BOLD}══════════════════════════════════════════════${NC}
${GREEN}${BOLD}   🐍 snakeEyes-theme — setup concluído!     ${NC}
${GREEN}${BOLD}══════════════════════════════════════════════${NC}

  ${BOLD}Tema GTK:${NC}      ${GTK_THEME:-Breeze}
  ${BOLD}Ícones:${NC}        ${ICON_THEME:-YAMIS}
  ${BOLD}Cursor:${NC}        ${CURSOR_THEME:-Bibata-Modern-Ice} (${CURSOR_SIZE:-24}px)
  ${BOLD}Color scheme:${NC}  SnakeEyes
  ${BOLD}Dark mode:${NC}     ativado

  ${YELLOW}→ Próximos passos:${NC}
    1. source ~/.zshrc         → ativa docker.sh e configs do shell
    2. Reinicie o sistema      → aplica cursor, DPI e color scheme
    3. System Settings         → confirme tema Breeze e ícones YAMIS

  ${BOLD}Docker:${NC}
    dockerstart    → inicia o serviço
    dockerstop     → para (confirma se tiver containers rodando)
    dockerstatus   → painel completo de status
    dockerrestart  → reinicia

  ${BLUE}Repo:${NC} https://github.com/MoisesHsilva1/snakeEyes-theme
"
