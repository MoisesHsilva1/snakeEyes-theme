#!/bin/bash

_DOCKER_GREEN='\033[0;32m'
_DOCKER_RED='\033[0;31m'
_DOCKER_YELLOW='\033[1;33m'
_DOCKER_BLUE='\033[0;34m'
_DOCKER_BOLD='\033[1m'
_DOCKER_NC='\033[0m'

_docker_check() {
  if ! command -v docker &>/dev/null; then
    echo -e "${_DOCKER_RED}[✗]${_DOCKER_NC} Docker não instalado."
    return 1
  fi
  return 0
}

dockerstart() {
  _docker_check || return 1
  echo -e "${_DOCKER_BLUE}[→]${_DOCKER_NC} Iniciando Docker..."
  sudo systemctl start docker
  sleep 1
  systemctl is-active --quiet docker \
    && echo -e "${_DOCKER_GREEN}[✓]${_DOCKER_NC} Docker rodando" \
    || echo -e "${_DOCKER_RED}[✗]${_DOCKER_NC} Falha ao iniciar"
}

dockerstop() {
  _docker_check || return 1
  local running=$(docker ps -q 2>/dev/null | wc -l)
  if [[ "$running" -gt 0 ]]; then
    echo -e "${_DOCKER_YELLOW}[!]${_DOCKER_NC} $running container(s) rodando. Parar mesmo assim? [s/N] "
    read -r confirm
    [[ "$confirm" != "s" && "$confirm" != "S" ]] && echo "Cancelado." && return 0
  fi
  echo -e "${_DOCKER_BLUE}[→]${_DOCKER_NC} Parando Docker..."
  sudo systemctl stop docker
  sleep 1
  ! systemctl is-active --quiet docker \
    && echo -e "${_DOCKER_GREEN}[✓]${_DOCKER_NC} Docker parado" \
    || echo -e "${_DOCKER_RED}[✗]${_DOCKER_NC} Falha ao parar"
}

dockerstatus() {
  _docker_check || return 1
  echo -e "\n${_DOCKER_BOLD}── Docker ──────────────────────────────────────${_DOCKER_NC}"
  systemctl is-active --quiet docker \
    && echo -e "  Status: ${_DOCKER_GREEN}● rodando${_DOCKER_NC}" \
    || echo -e "  Status: ${_DOCKER_RED}○ parado${_DOCKER_NC}"
  systemctl is-enabled --quiet docker \
    && echo -e "  Boot:   ${_DOCKER_GREEN}habilitado${_DOCKER_NC}" \
    || echo -e "  Boot:   ${_DOCKER_YELLOW}desabilitado${_DOCKER_NC}"
  if systemctl is-active --quiet docker; then
    local running=$(docker ps -q 2>/dev/null | wc -l)
    local total=$(docker ps -aq 2>/dev/null | wc -l)
    echo -e "  Containers: ${_DOCKER_GREEN}$running rodando${_DOCKER_NC} / $total total"
    [[ "$running" -gt 0 ]] && docker ps --format "  → {{.Names}}  {{.Image}}  {{.Status}}"
  fi
  echo -e "${_DOCKER_BOLD}────────────────────────────────────────────────${_DOCKER_NC}\n"
}

dockerrestart() {
  _docker_check || return 1
  echo -e "${_DOCKER_BLUE}[→]${_DOCKER_NC} Reiniciando Docker..."
  sudo systemctl restart docker
  sleep 1
  systemctl is-active --quiet docker \
    && echo -e "${_DOCKER_GREEN}[✓]${_DOCKER_NC} Docker reiniciado" \
    || echo -e "${_DOCKER_RED}[✗]${_DOCKER_NC} Falha ao reiniciar"
}
EOF