#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Iniciando a reconstrução do ambiente snakeEyes...${NC}"

sudo pacman -Syu --noconfirm

sudo pacman -S --needed - < pkg/pacman-list.txt

if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd -
fi

yay -S --needed - < pkg/aur-list.txt

echo "Restaurando configurações..."

echo -e "${GREEN}Sistema restaurado com sucesso!${NC}"