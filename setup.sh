
#!/bin/bash

# --- INSTRUCTIONS ---
#  Connect to the Internet: If you are using Wi-Fi, you'll need to connect to it first. You can use the iwctl
#      utility for this.
#
#     # Start the interactive prompt
#     iwctl
#
#     # List your Wi-Fi devices (e.g., wlan0)
#     device list
#
#     # Scan for networks
#     station <device_name> scan
#
#     # List available networks
#     station <device_name> get-networks
#
#     # Connect to your network
#     station <device_name> connect "Your_SSID"
#
#     # Type your password when prompted, then type 'exit'
#
#
#    NOTE: Or directly execute this
#
#    iwctl --passphrase passphrase station name connect SSID
#
#     NOTE: more on the topic could be found here https://wiki.archlinux.org/title/Iwd#iwctl
#
# This script interactively automates a clean installation of Arch Linux.
# It is designed to be run on a pre-partitioned disk.
#
# USAGE:
# 0. pacman -Sy wget
#
# 1. From the Arch Linux live environment, download the script (replace with your actual URL):
#    wget https://raw.githubusercontent.com/bdryanovski/arch/main/setup.sh
#
# 2. Make the script executable:
#    chmod +x setup.sh
#
# 3. Run the script. It will prompt you for all necessary information:
#    ./setup.sh
#
# --- WARNINGS ---
#
# - This script is for pre-partitioned disks. It will format the partitions
#   you specify, permanently erasing all data on them.
#
# - Always review scripts from the internet before running them.
#
# ---

# --- Interactive Configuration ---
echo "Detecting Wi-Fi interface..."                                                             │
# Find the first wireless interface (usually starts with 'w')                                   │
WIFI_INTERFACE=$(ls /sys/class/net | grep '^w' | head -n 1)                                     │
  if [ -z "$WIFI_INTERFACE" ]; then                                                               │
  echo "Could not find a Wi-Fi interface. Aborting."                                          │
 │exit 1                                                                                      │
  fi                                                                                              │
echo "Found Wi-Fi interface: ${WIFI_INTERFACE}"                                                 │

echo "--- Arch Linux Interactive Installer ---"
echo "Please provide the following information."

# Get partition info
read -p "Enter the EFI System Partition path (e.g., /dev/sda1 or /dev/nvme0n1p5): " EFI_PARTITION
read -p "Enter the Linux Root Partition path (e.g., /dev/sda2 or /dev/nvme0n1p7): " ROOT_PARTITION
read -p "Enter the Swap Partition path (/dev/nvme0n1p6): " SWAP_PARTITION

# Get system info
read -p "Enter the desired hostname for the new system: " HOSTNAME
read -p "Enter the username for your new user: " USERNAME

# Get passwords
while true; do
    read -sp "Enter the password for the root user and your new user: " PASSWORD
    echo
    read -sp "Confirm the password: " PASSWORD_CONFIRM
    echo
    [ "$PASSWORD" = "$PASSWORD_CONFIRM" ] && break
    echo "Passwords do not match. Please try again."
done

# Get Wi-Fi info
read -p "Enter your Wi-Fi network name (SSID): " WIFI_SSID
read -sp "Enter your Wi-Fi password: " WIFI_PASSWORD
echo

# Ask about dual boot
read -p "Do you want to configure dual boot with Windows? (yes/no): " SETUP_DUAL_BOOT

# --- Pre-flight Check ---
echo "---"
echo "Configuration complete. The following partitions will be FORMATTED:"
echo "  - EFI:   $EFI_PARTITION"
echo "  - Root:  $ROOT_PARTITION"
echo "  - Swap:  $SWAP_PARTITION (if specified)"
echo
read -p "WARNING: All data on these partitions will be lost. Are you sure you want to continue? (yes/no): " CONFIRM_FORMAT
if [ "$CONFIRM_FORMAT" != "yes" ]; then
    echo "Installation aborted by user."
    exit 1
fi
echo "---"


# --- Script Start ---

echo "Starting Arch Linux installation..."

# Format the partitions
echo "Formatting partitions..."
mkfs.fat -F32 "${EFI_PARTITION}"
mkswap "${SWAP_PARTITION}"
mkfs.ext4 "${ROOT_PARTITION}"

# Mount the partitions
echo "Mounting file systems..."
mount "${ROOT_PARTITION}" /mnt
mkdir -p /mnt/boot
mount "${EFI_PARTITION}" /mnt/boot

swapon "${SWAP_PARTITION}"

# Install the base system
echo "Installing base system (this may take a while)..."
pacstrap -K /mnt base linux linux-firmware base-devel

echo "Installation bonus packages..."
pacstrap -K /mnt vim networkmanager texinfo grub os-prober efibootmgr dosfstools mtools base-devel git sudo intel-ucode

# Generate fstab
echo "Generating fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# Chroot into the new system and configure it
echo "Entering chroot and configuring the system..."
arch-chroot /mnt <<EOF

# Set the time zone
ln -sf /usr/share/zoneinfo/Europe/Sofia /etc/localtime
hwclock --systohc

# Set the locale
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# Set the hostname
echo "${HOSTNAME}" > /etc/hostname

# Set passwords
echo "root:${PASSWORD}" | chpasswd
useradd -m -G wheel -s /bin/bash "${USERNAME}"
echo "${USERNAME}:${PASSWORD}" | chpasswd

# Grant sudo privileges
echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers

# Install necessary packages
pacman -S --noconfirm --needed wpa_supplicant neovim git

# Configure Wi-Fi
cat > /etc/wpa_supplicant/wpa_supplicant-${WIFI_INTERFACE}.conf <<EOT
ctrl_interface=/run/wpa_supplicant
update_config=1

network={
    ssid="${WIFI_SSID}"
    psk="${WIFI_PASSWORD}"
}
EOT

cat > /etc/systemd/network/25-wireless.network <<EOT
[Match]
Name=${WIFI_INTERFACE}

[Network]
DHCP=yes
EOT

# Enable network services
systemctl enable wpa_supplicant@${WIFI_INTERFACE}.service
systemctl enable systemd-networkd.service

# Configure Bootloader
if [ "${SETUP_DUAL_BOOT}" = "yes" ]; then
    echo "Configuring GRUB for dual boot with Windows..."
    pacman -S --noconfirm --needed grub os-prober efibootmgr

    # Enable os-prober
    sed -i 's/#GRUB_DISABLE_OS_PROBER=false/GRUB_DISABLE_OS_PROBER=false/' /etc/default/grub

    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
else
    echo "Installing GRUB for a single-boot system..."
    pacman -S --noconfirm --needed grub efibootmgr
    grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
    grub-mkconfig -o /boot/grub/grub.cfg
fi

EOF

# Unmount the partitions
echo "Unmounting partitions..."
umount -R /mnt

echo "Installation complete. You can now reboot."
