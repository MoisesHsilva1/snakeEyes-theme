#!/bin/bash

sudo pacman -Syu --needed --noconfirm - < pkg/pacman-list.txt

if ! command -v yay &> /dev/null; then
    git clone https://aur.archlinux.org/yay.git /tmp/yay
    cd /tmp/yay && makepkg -si --noconfirm && cd -
fi

yay -S --needed --noconfirm - < pkg/aur-list.txt

mkdir -p ~/.themes ~/.icons ~/.local/share/fonts

cp -r themes/.themes/* ~/.themes/ 2>/dev/null
cp -r themes/.icons/* ~/.icons/ 2>/dev/null
cp -r themes/fonts/* ~/.local/share/fonts/ 2>/dev/null
fc-cache -fv

apply_dotfile() {
    rm -rf "$2"
    ln -sf "$1" "$2"
}

apply_dotfile ~/snakeEyes/dotfiles/kitty ~/.config/kitty
apply_dotfile ~/snakeEyes/dotfiles/nvim ~/.config/nvim
apply_dotfile ~/snakeEyes/dotfiles/.zshrc ~/.zshrc