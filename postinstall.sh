#!/bin/bash
#postinstall

#manual link doas to sudo
doas mv /usr/bin/sudo /usr/bin/sudo.BAK
doas ln -s $(which doas) /usr/bin/sudo

#install correct opendoas link
mkdir Git $$ cd Git && git clone https://aur.archlinux.org/opendoas-sudo.git && cd opendoas-sudo && makepkg -si
#install paru pacman wrapper
cd ~/Git && git clone https://aur.archlinux.org/paru.git && cd paru && makepkg -si 
 
