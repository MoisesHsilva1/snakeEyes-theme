cat > ~/snakeEyes-theme/scripts/docker/docker.sh << 'EOF'
#!/bin/bash

_G='\033[0;32m'; _R='\033[0;31m'; _Y='\033[1;33m'; _B='\033[0;34m'; _BOLD='\033[1m'; _NC='\033[0m'

_docker_check() {
  ! command -v docker &>/dev/null && echo -e "${_R}[✗]${_NC} Docker não instalado." && return 1
  return 0
}

dockerstart() {
  _docker_check || return 1
  echo -e "${_B}[→]${_NC} Iniciando Docker..."
  sudo systemctl start docker && sleep 1
  systemctl is-active --quiet docker \
    && echo -e "${_G}[✓]${_NC} Docker rodando" \
    || echo -e "${_R}[✗]${_NC} Falha ao iniciar"
}

dockerstop() {
  _docker_check || return 1
  local running; running=$(docker ps -q 2>/dev/null | wc -l)
  if [[ "$running" -gt 0 ]]; then
    echo -e "${_Y}[!]${_NC} $running container(s) rodando. Parar mesmo assim? [s/N] "
    read -r confirm
    [[ "$confirm" != "s" && "$confirm" != "S" ]] && echo "Cancelado." && return 0
  fi
  echo -e "${_B}[→]${_NC} Parando Docker..."
  sudo systemctl stop docker && sleep 1
  ! systemctl is-active --quiet docker \
    && echo -e "${_G}[✓]${_NC} Docker parado" \
    || echo -e "${_R}[✗]${_NC} Falha ao parar"
}

dockerstatus() {
  _docker_check || return 1
  echo -e "\n${_BOLD}── Docker ──────────────────────────────────────${_NC}"
  systemctl is-active --quiet docker \
    && echo -e "  Status: ${_G}● rodando${_NC}" \
    || echo -e "  Status: ${_R}○ parado${_NC}"
  systemctl is-enabled --quiet docker \
    && echo -e "  Boot:   ${_G}habilitado${_NC}" \
    || echo -e "  Boot:   ${_Y}desabilitado${_NC}"
  if systemctl is-active --quiet docker; then
    local running; running=$(docker ps -q 2>/dev/null | wc -l)
    local total;   total=$(docker ps -aq 2>/dev/null | wc -l)
    echo -e "  Containers: ${_G}$running rodando${_NC} / $total total"
    [[ "$running" -gt 0 ]] && docker ps --format "  → {{.Names}}  {{.Image}}  {{.Status}}"
  fi
  echo -e "${_BOLD}────────────────────────────────────────────────${_NC}\n"
}

dockerrestart() {
  _docker_check || return 1
  echo -e "${_B}[→]${_NC} Reiniciando Docker..."
  sudo systemctl restart docker && sleep 1
  systemctl is-active --quiet docker \
    && echo -e "${_G}[✓]${_NC} Docker reiniciado" \
    || echo -e "${_R}[✗]${_NC} Falha ao reiniciar"
}
EOF