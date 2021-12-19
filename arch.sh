#!/bin/bash
# Gianmarco's Arch Installer Script
# Inspired by BugsWriter's arch-linux-magic
# Licensed under the GNU General Public License v3


# Intro text
echo "
 
██████╗░░██████╗░█████╗░██╗░░██╗███████╗███╗░░██╗░██████╗███████╗
██╔══██╗██╔════╝██╔══██╗██║░░██║██╔════╝████╗░██║██╔════╝██╔════╝
██║░░██║╚█████╗░██║░░╚═╝███████║█████╗░░██╔██╗██║╚█████╗░█████╗░░
██║░░██║░╚═══██╗██║░░██╗██╔══██║██╔══╝░░██║╚████║░╚═══██╗██╔══╝░░
██████╔╝██████╔╝╚█████╔╝██║░░██║███████╗██║░╚███║██████╔╝███████╗
╚═════╝░╚═════╝░░╚════╝░╚═╝░░╚═╝╚══════╝╚═╝░░╚══╝╚═════╝░╚══════╝

dschense's Arch Installer Script modifyed from
(C) 2021 Gianmarco Gargiulo - GPL v3
https://git.gianmarco.ga/gianmarco/gais

WARNING: this script is experimental.
Use at your own risk!

-------------------------------------
"


# Main installation
echo "Starting the main installation..."
reflector --latest 20 --sort rate --country Germany --save /etc/pacman.d/mirrorlist --protocol http --download-timeout 5
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf
loadkeys de
timedatectl set-ntp true

# Partitioning with cfdisk
lsblk
echo "You'll be asked for where to install your OS. Use cfdisk to partition the drive.
These are some reccommended partition schemes.
For a UEFI system:
    Part. 1 = EFI, min 300M
    Part. 2 = root (where the actual system will be installed)
    Part. 3 = swap (optional), min 512M
For a traditional BIOS / MBR system:
    Part. 1 = BIOS Boot, 512M
    Part. 2 = root (where the actual system will be installed)
    Part. 3 = swap (optional), min 512M
For more information go RTFM at wiki.archlinux.org.
Type drives/partitions as full paths (e.g. '/dev/sda' or '/dev/sda1').
Target drive: "
read drive
cfdisk $drive

# Format and mount partitions
lsblk

# Root
echo "Target root partition (MUST BE FORMATTED so make sure you have nothing important on it): "
read partition
mkfs.ext4 $partition

# Boot
read -p "Did you make an EFI partition for UEFI? [y/n] " answer
if [[ $answer = y ]] ; then
  echo "Target EFI partition: "
  read efipartition
  mkfs.vfat -F 32 $efipartition
else
  echo "Target Legacy Boot partition: "
  read legacyboot
  mkfs.ext4 $legacyboot
fi

# Swap
read -p "Did you make a swap partition? [y/n] " answer
if [[ $answer = y ]] ; then
  echo "Target swap partition: "
  read swappartition
  swapon $swappartition
fi

# Mounting
mount $partition /mnt
mkdir /mnt/boot
mount $legacyboot /mnt/boot

# Install Base System
pacstrap /mnt base base-devel linux-zen linux-zen-headers
genfstab -U /mnt >> /mnt/etc/fstab

sed '1,/^# Configuration$/d' arch.sh > /mnt/arch_part2.sh
chmod +x /mnt/arch_part2.sh
arch-chroot /mnt ./arch_part2.sh
exit


# Configuration
echo "Starting the configuration..."
pacman -Sy
pacman -S --noconfirm sed
sed -i "s/^#ParallelDownloads = 5$/ParallelDownloads = 15/" /etc/pacman.conf

# TimeZone
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# Locale
echo "de_DE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=de_DE.UTF-8" > /etc/locale.conf
echo "KEYMAP=de" > /etc/vconsole.conf

# Hostname
echo "Type a hostname for your system: "
read hostname
echo $hostname > /etc/hostname
echo "127.0.0.1       localhost" >> /etc/hosts
echo "::1             localhost" >> /etc/hosts
echo "127.0.1.1       $hostname.localdomain $hostname" >> /etc/hosts

# Initial ramdisk
mkinitcpio -P

# Set root PW
echo "You will now be asked to input a password for the root user."
passwd
pacman --noconfirm -S grub efibootmgr os-prober

# Setup GRUB
read -p "Did you make an EFI partition for UEFI? [y/n] " answer
if [[ $answer = y ]] ; then
lsblk
echo "Enter EFI partition: " 
read efipartition
mkdir /boot/efi
mount $efipartition /boot/efi
grub-install --target=x86_64-efi --bootloader-id=grub_uefi --recheck
else
lsblk
echo "Enter boot drive for MBR (/dev/sda NOT /dev/sda1): "
read bootdrive
grub-install --target=i386-pc $bootdrive
fi
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/g' /etc/default/grub
grub-mkconfig -o /boot/grub/grub.cfg

# Install packages
curl -LO "" -o /tmp/packages.txt
sed -e "/^#/d" -e "s/#.*//" /tmp/packages.txt | pacman -S --needed -

# Enable NetworkManager
systemctl enable NetworkManager.service

# Create local user with sudo rights
echo "permit persist keepenv :wheel as root" > /etc/doas.conf
echo "Create your own user account. It will have administrative privileges (wheel)."
echo "Username: "
read username
useradd -m -G wheel -s /bin/zsh $username
passwd $username

# Install packetmanager YAY
runuser -l $username -c 'cd && mkdir Git && cd Git && git clone https://aur.archlinux.org/yay-bin.git && cd yay-bin && makepkg -si && yay -S --noconfirm librewolf-bin librewolf-extension-dark-reader librewolf-extension-localcdn librewolf-extension-plasma-integration librewolf-extension-return-youtube-dislike-git librewolf-ublock-origin opendoas-sudo'

# unmount installed filesystem
umount -R /mnt

echo "
----------------------------------------------------------------------------------

Installation completed! You may now reboot into your freshly installed Arch Linux.
(C) 2021 Gianmarco Gargiulo - GPL v3 - www.gianmarco.ga
https://git.gianmarco.ga/gianmarco/gais
"
