#!/usr/bin/env bash

# Iconos WhiteSur Grey
git clone https://github.com/vinceliuice/WhiteSur-icon-theme.git
cd WhiteSur-icon-theme || return
./install.sh -t grey
cd ..
rm -rf WhiteSur-icon-theme

dconf write /org/gnome/desktop/interface/icon-theme "'WhiteSur-grey'"

# Cursores WhiteSur
git clone https://github.com/vinceliuice/WhiteSur-cursors.git
cd WhiteSur-cursors || return
./install.sh
cd ..
rm -rf WhiteSur-cursors

dconf write /org/gnome/desktop/interface/cursor-theme "'WhiteSur-cursors'"

# Tema WhiteSur GTK
pkill firefox
git clone https://github.com/vinceliuice/WhiteSur-gtk-theme.git --depth=1
cd WhiteSur-gtk-theme || return
./install.sh -l -N glassy --shell -i fedora
./tweaks.sh -f
./tweaks.sh -F
sudo flatpak override --filesystem=xdg-config/gtk-4.0
if [ ! -d ~/.themes ]; then
    mkdir -p ~/.themes
fi
tar -xf ./release/WhiteSur-Dark.tar.xz -C ~/.themes/
cd ..
rm -rf WhiteSur-gtk-theme

dconf write /org/gnome/desktop/interface/color-scheme "'prefer-dark'"
dconf write /org/gnome/desktop/interface/gtk-theme "'WhiteSur-Dark'"
dconf write /org/gnome/shell/extensions/user-theme/name "'WhiteSur-Dark'"

# Tema WhiteSur KDE
git clone https://github.com/vinceliuice/WhiteSur-kde.git
cd WhiteSur-kde || return
./install.sh
cd ..
rm -rf WhiteSur-kde
mkdir ~/.config/environment.d
touch ~/.config/environment.d/90-dms.conf
echo 'QT_QPA_PLATFORMTHEME=qt6ct' >> ~/.config/environment.d/90-dms.conf
touch ~/.config/kdeglobals
echo -e "[KDE]\nwidgetStyle=qt6ct-style\n\n[Icons]\nTheme=WhiteSur-grey-dark" >> ~/.config/kdeglobals
sed -i '/\[Appearance\]/a\icon_theme=WhiteSur-grey' ~/.config/qt6ct/qt6ct.conf

# Greeter
dms greeter sync
