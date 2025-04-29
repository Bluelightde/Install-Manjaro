#!/usr/bin/env bash
set -euo pipefail

# Fedora-Setup-Skript mit schlankem Nerd-Fonts-Install

echo "1) Cache & Metadaten aktualisieren…"
sudo pacman -Syu --noconfirm

echo "2) Pakete installieren…"
packages=(
  zsh neovim git htop kitty qalculate-gtk xclip
  libreoffice libreoffice-still-de flameshot gimp chromium
  thunderbird putty vlc gnome-disk-utility btop fzf hyfetch
  gpick rpi-imager papirus-icon-theme unzip virtualbox virtualbox-guest-utils
  ttf-jetbrains-mono-nerd flatpak github-cli
)
sudo pacman -S --needed --noconfirm "${packages[@]}"

echo "3) Flatpak & Flathub einrichten…"
sudo flatpak remote-add --if-not-exists flathub \
     https://flathub.org/repo/flathub.flatpakrepo

echo "4) Flatpak-Apps installieren…"
flatpaks=(
  com.github.tchx84.Flatseal
  com.logseq.Logseq
  com.brave.Browser
  io.gitlab.librewolf-community
  org.onlyoffice.desktopeditors
  com.vscodium.codium
  io.github.ungoogled_software.ungoogled_chromium
  io.anytype.anytype
  org.nomacs.ImageLounge
)
for pkg in "${flatpaks[@]}"; do
  echo "   → $pkg"
  if ! sudo flatpak install -y flathub "$pkg"; then
    echo "     ! Paket $pkg nicht gefunden, übersprungen."
  fi
done

echo "5) nvchad installieren"
git clone https://github.com/NvChad/starter ~/.config/nvim && nvim

echo "6) Oh my Zsh installieren"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

xfce4-panel --restart
echo "✓ Alles erledigt!"

