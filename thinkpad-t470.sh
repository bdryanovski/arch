#!/bin/bash


# This script is designed to set up a ThinkPad T470 with Arch Linux.
# It will install necessary packages, configure the system, and set up the environment.
# It assumes you have a pre-partitioned disk and are running this from the Arch Linux
# live environment.
#
# Usage:
# 1. Download the script:
#   wget https://raw.githubusercontent.com/bdryanovski/arch/main/thinkpad-t470.sh
# 2. Make it executable:
#  chmod +x thinkpad-t470.sh
# 3. Run the script:
#  ./thinkpad-t470.sh
#
#

# --- Interactive Configuration ---
echo "Setup for ThinkPad T470 with Arch Linux"

echo "Arch documentation: https://wiki.archlinux.org/title/Lenovo_ThinkPad_T470"

pacman -Sy intel-ucode

echo "Intel CPU throttle:"
pacman -S throttled
systemctl enable --now throttled.service
