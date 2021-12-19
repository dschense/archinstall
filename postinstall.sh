#!/bin/bash
#postinstall

doas mv /usr/bin/sudo /usr/bin/sudo.BAK
doas ln -s $(which doas) /usr/bin/sudo

mkdir Git $$ cd Git && git clone https://aur.archlinux.org/opendoas-sudo.git && cd opendoas-sudo && makepkg -si
doas pacman -S --needed base-devel
cd ~/Git && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si 
 