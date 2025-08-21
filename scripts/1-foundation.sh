#!/bin/bash

sudo pacman -S --needed --noconfirm base-devel gum

if ! command -v yay &>/dev/null; then
  cd /tmp
  git clone https://aur.archlinux.org/yay-bin.git
  cd yay-bin
  makepkg -si --noconfirm
  cd -
  rm -rf yay-bin
  cd ~

  # Add fun and color to the pacman installer
  sudo sed -i '/^\[options\]/a Color\nILoveCandy' /etc/pacman.conf
fi

echo -e "\nEnter identification for git and autocomplete..."
export USER_NAME=$(gum input --placeholder "Enter full name" --prompt "Name> ")
export USER_EMAIL=$(gum input --placeholder "Enter email address" --prompt "Email> ")

# Set identification from install inputs
if [[ -n "${USER_NAME//[[:space:]]/}" ]]; then
  git config --global user.name "$USER_NAME"
fi

if [[ -n "${USER_EMAIL//[[:space:]]/}" ]]; then
  git config --global user.email "$USER_EMAIL"
fi


basic=(
  curl,
  btop,
  jq
  )

for package in "${basic[@]}"; do
  if ! pacman -Qi "$package" &>/dev/null; then
    echo "Installing $package..."
    sudo pacman -S --noconfirm --needed "$package"
  else
    echo "$package is already installed."
  fi
done

#
# yay -S --noconfirm --needed \
#   curl unzip inetutils impala \
#   fd eza fzf ripgrep zoxide bat jq \
#   wl-clipboard fastfetch btop \
#   man tldr less whois plocate bash-completion \
#   alacritty
