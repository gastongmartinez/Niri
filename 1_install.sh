#!/usr/bin/env bash

# Validacion del usuario ejecutando el script
R_USER=$(id -u)
if [ "$R_USER" -ne 0 ]; then
    echo -e "\nDebe ejecutar este script como root o utilizando sudo.\n"
    exit 1
fi

read -rp "Establecer el password para root? (S/N): " PR
if [[ $PR =~ ^[Ss]$ ]]; then
    passwd root
fi

read -rp "Establecer el nombre del equipo? (S/N): " HN
if [[ $HN =~ ^[Ss]$ ]]; then
    read -rp "Ingrese el nombre del equipo: " EQUIPO
    if [ -n "$EQUIPO" ]; then
        echo -e "$EQUIPO" > /etc/hostname
    fi
fi

systemctl enable sshd

# Ajuste Swappiness
su - root <<EOF
        echo -e "vm.swappiness=10\n" >> /etc/sysctl.d/90-sysctl.conf
EOF

# Configuracion DNF
{
    echo 'fastestmirror=1'
    echo 'max_parallel_downloads=10'
} >> /etc/dnf/dnf.conf

# RPMFusion
dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-"$(rpm -E %fedora)".noarch.rpm -y
dnf install https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-"$(rpm -E %fedora)".noarch.rpm -y

# MESA
read -rp "Cambiar drivers de video a MESA Freeworld? (S/N): " MESA
if [[ $MESA =~ ^[Ss]$ ]]; then
    dnf swap mesa-va-drivers mesa-va-drivers-freeworld -y
    dnf swap mesa-vdpau-drivers mesa-vdpau-drivers-freeworld -y
fi

# Repositorios VSCode y Powershell
rpm --import https://packages.microsoft.com/keys/microsoft.asc
sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\nautorefresh=1\ntype=rpm-md\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | tee /etc/yum.repos.d/vscode.repo > /dev/null'
curl -sSL -O https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
rpm -i packages-microsoft-prod.rpm
rm packages-microsoft-prod.rpm
dnf check-update
dnf makecache

# Brave
rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
dnf config-manager addrepo --from-repofile=https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo

# Librewolf
rpm --import https://rpm.librewolf.net/pubkey.gpg
curl -fsSL https://repo.librewolf.net/librewolf.repo | pkexec tee /etc/yum.repos.d/librewolf.repo

# Google Chrome
sh -c 'echo -e "[google-chrome]\nname=google-chrome\nbaseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64\nenabled=1\ngpgcheck=1\ngpgkey=https://dl.google.com/linux/linux_signing_key.pub" > /etc/yum.repos.d/google-chrome.repo'

# PGAdmin
rpm -i https://ftp.postgresql.org/pub/pgadmin/pgadmin4/yum/pgadmin4-fedora-repo-2-1.noarch.rpm

# CORP
dnf copr enable atim/lazygit -y
dnf copr enable avengemedia/dms -y
dnf copr enable brycensranch/gpu-screen-recorder-git -y
dnf copr enable avengemedia/danklinux -y

dnf update -y

USER=$(grep "1000" /etc/passwd | awk -F : '{ print $1 }')

############################# Codecs ###########################################
dnf install libavcodec-freeworld -y
dnf group install multimedia -y
dnf install gstreamer1-plugins-{bad-\*,good-\*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel -y
dnf swap ffmpeg-free ffmpeg --allowerasing -y
################################################################################

############################### Apps Generales ################################
PAQUETES=(
    #### Powermanagement ####
    'powertop'

    #### WEB ####
    'firefox'
    'google-chrome-stable'
    'librewolf'
    'thunderbird'
    'remmina'
    'qbittorrent'
    'brave-browser'

    #### Shells ####
    'zsh'
    'zsh-autosuggestions'
    'zsh-syntax-highlighting'
    'dialog'
    'autojump'
    'autojump-zsh'
    'ShellCheck'
    'powershell'

    #### Archivos ####
    'mc'
    'thunar'
    'stow'
    'ripgrep'
    'autofs'

    #### Sistema ####
    'flatpak'
    'tldr'
    'helix'
    'lsd'
    'corectrl'
    'p7zip'
    'unrar'
    'alacritty'
    'htop'
    'lshw'
    'lshw-gui'
    'powerline'
    'libreoffice'
    'neovim'
    'python3-neovim'
    'emacs'
    'scribus'
    'flameshot'
    'klavaro'
    'fd-find'
    'fzf'
    'the_silver_searcher'
    'qalculate'
    'calibre'
    'foliate'
    'hunspell-de'
    'pandoc'
    'ulauncher'
    'dnfdragora'
    'timeshift'
    'solaar'
    'splix'
    'fastfetch'

    #### Multimedia ####
    'vlc'
    'python-vlc'
    'mpv'
    'HandBrake'
    'HandBrake-gui'
    'audacious'
    'clipgrab'

    #### Juegos ####
    'chromium-bsu'

    #### Redes ####
    'nmap'
    'wireshark'
    'firewall-applet'
    'NetworkManager-tui'
    #'gns3-gui'
    #'gns3-server'

    #### Diseño ####
    'gimp'
    'inkscape'
    'krita'
    'blender'

    #### DEV ####
    'git'
    'clang'
    'clang-tools-extra'
    'cmake'
    'meson'
    'filezilla'
    'sbcl'
    'golang'
    'lldb'
    'code'
    'tidy'
    'yarnpkg'
    'lazygit'
    'pcre-cpp'
    'httpd'
    'php'
    'php-gd'
    'php-mysqlnd'
    'dotnet-sdk-10.0'

    #### Fuentes ####
    'terminus-fonts'
    'fontawesome-fonts'
    'cascadia-code-fonts'
    'texlive-roboto'
    'dejavu-fonts-all'
    'fira-code-fonts'
    'cabextract'
    'xorg-x11-font-utils'
    'texlive-caladea'
    'fontforge'

    ### Bases de datos ###
    'postgresql-server'
    'postgis'
    'postgis-client'
    'postgis-utils'
    'pgadmin4'
    'sqlite'
    'sqlite-analyzer'
    'sqlite-tools'
    'sqlitebrowser'

    ### Cockpit ###
    'cockpit'
    'cockpit-sosreport'
    'cockpit-machines'
    'cockpit-podman'
    'cockpit-selinux'

    ### Virtualizacion ###
    'virt-manager'
    'ebtables-services'
    'bridge-utils'
    'libguestfs'

    ### Niri ###
    'niri'
    'dms'
    'dms-greeter'
    'qt6ct'

    ### Gnome ###
    'gnome-commander'
    'file-roller-nautilus'
    'qalculate-gtk'
    'dconf-editor'

    # Dependencias Noctalia Shell
    #dnf install ddcutil -y
    #dnf install brightnessctl -y
    #dnf install gpu-screen-recorder-ui -y
    #dnf install wlsunset -y
    #dnf install evolution-data-server -y
)

for PAQ in "${PAQUETES[@]}"; do
    dnf install "$PAQ" -y
done

rpm -i https://downloads.sourceforge.net/project/mscorefonts2/rpms/msttcore-fonts-installer-2.6-1.noarch.rpm
dnf install https://corretto.aws/downloads/latest/amazon-corretto-21-x64-linux-jdk.rpm -y
dnf install https://corretto.aws/downloads/latest/amazon-corretto-25-x64-linux-jdk.rpm -y
###############################################################################

################################ Wallpapers #####################################
echo -e "\nInstalando wallpapers..."
git clone https://github.com/gastongmartinez/wallpapers.git
mv -f wallpapers/ "/usr/share/backgrounds/"
#################################################################################

############################### GRUB ############################################
git clone https://github.com/vinceliuice/grub2-themes.git
cd grub2-themes || return
./install.sh
cd .. || return
#################################################################################

rm -rf grub2-themes

usermod -aG libvirt "$USER"
usermod -aG kvm "$USER"

postgresql-setup --initdb --unit postgresql
systemctl enable --now cockpit.socket
firewall-cmd --add-service=cockpit --permanent
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent

alternatives --set java /usr/lib/jvm/java-21-amazon-corretto/bin/java
alternatives --set javac /usr/lib/jvm/java-21-amazon-corretto/bin/javac

systemctl set-default graphical.target
systemctl enable greetd
sed -i 's/"agreety --cmd \/bin\/sh"/"\/usr\/bin\/dms-greeter --command niri"/g' '/etc/greetd/config.toml'

cd /usr/bin || return
ln -s lldb-dap lldb-vscode
