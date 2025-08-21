#!/bin/bash


echo "Configuration for Arch Linux"

for file in scripts/*.sh; do
    if [[ -f "$file" ]]; then
        echo "Running $file"
        source "$file"
    else
        echo "Skipping $file (not a file)"
    fi
done

#
# pacman -S \
#     `# archive   ` p7zip zip unzip unrar \
#     `# audio     ` pulseaudio pulseaudio-alsa pavucontrol alsa-plugins alsa-utils \
#     `# bluetooth ` bluez bluez-utils pulseaudio-bluetooth \
#     `# code      ` neovim git python python-pip go rust \
#     `# desktop   ` nitrogen i3lock xdg-desktop-portal xdg-desktop-portal-gtk \
#     `# fonts     ` adobe-source-code-pro-fonts noto-fonts \
#     `# misc      ` bind-tools feh tk pdftk boost qt5-xmlpatterns fortune-mod linux-headers \
#     `# net       ` net-tools wget tcpdump tcpreplay traceroute nmap wireshark-qt remmina \
#     `# terminal  ` alacritty ranger \
#     `# util      ` btop tree scrot acpi cloc whois speedtest-cli ntp strace streamlink croc man-db \
#


pacman -Syyu

gum confirm "Reboot to apply all settings?" && reboot
