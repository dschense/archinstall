#!/bin/bash

# Clone Suckless dwm and st
cd ~/Git
git clone https://git.suckless.org/dwm #dwm window manager
git clone https://git.suckless.org/st # terminal

# install needed software
doas pacman -Sy xorg-server xorg-xinit libx11 libxinerama libxft webkit2gt

# exec dwm .xinitrc
cd ~/
echo "exec dwm" > .xinitrc

#compile st
cd ~/Git/st
doas make clean install

#compile dwm
cd ~/Git/dwm
doas make clean install
sed -i 's/\/bin\/sh/\/usr\/local\/bin\/st/' ~/Git/dwm/config.h

#startx on login
echo -e "\nstartx" >> ~/.bash_profile

echo "dwm $ st installed. Reboot or relogin your user."