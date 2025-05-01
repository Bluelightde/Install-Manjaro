#!/usr/bin/env bash
set -euo pipefail
trap 'echo "x Fehler in Zeile $LINENO"; exit 1' ERR

# Logging
exec > >(tee -i setup.log) 2>&1

# Paketmanager-Detection
if command -v pacman &>/dev/null; then
  DISTRO="arch"
  PM_UP="sudo pacman -Syu --noconfirm"
  PM_IN="sudo pacman -S --needed --noconfirm"
#elif command -v dnf &>/dev/null; then
 # PM_UP="sudo dnf upgrade --refresh -y"
 # PM_IN="sudo dnf install -y"
elif command -v apt &>/dev/null; then
  DISTRO="debian"
  PM_UP="sudo apt-get update && sudo apt -y upgrade"
  PM_IN="sudo apt-get -y install"
else
  echo "Unsupported distro" >&2
  exit 1
fi


echo "1) Cache & Metadaten aktualisieren…"
$PM_UP

echo "2) Pakete installieren…"
packages_arch=(
  zsh neovim git htop kitty qalculate-gtk xclip
  libreoffice libreoffice-still-de flameshot gimp
  thunderbird putty vlc gnome-disk-utility btop fzf hyfetch
  gpick rpi-imager papirus-icon-theme unzip virtualbox virtualbox-guest-utils
  ttf-jetbrains-mono-nerd flatpak github-cli wmctrl bat
)

packages_debian=(
  zsh neovim git htop kitty qalculate-gtk xclip
  libreoffice libreoffice-l10n-de flameshot gimp
  thunderbird putty vlc gnome-disk-utility btop fzf hyfetch
  gpick rpi-imager papirus-icon-theme unzip virtualbox virtualbox-guest-utils
  fonts-jetbrains-mono flatpak wmctrl bat
)

#packages_fedora=(
#  zsh neovim git htop kitty qalculate xclip
#  libreoffice libreoffice-langpack-de flameshot gimp
#  thunderbird putty vlc gnome-disk-utility btop fzf hyfetch
#  gpick rpi-imager papirus-icon-theme unzip nomacs flatpak
#  bat 
#)

echo "2) Pakete installieren…"
if [[ $DISTRO == "arch" ]]; then
  $PM_IN "${packages_arch[@]}"
elif [[ $DISTRO == "fedora" ]]; then
  $PM_IN "${packages_fedora[@]}"
else
  $PM_IN "${packages_debian[@]}"
fi

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
  io.github.shiftey.Desktop
)
for pkg in "${flatpaks[@]}"; do
  echo "   → $pkg"
  if ! sudo flatpak install -y flathub "$pkg"; then
    echo "     ! Paket $pkg nicht gefunden, übersprungen."
  fi
done

echo "5) NvChad installieren/aktualisieren…"
NVCHAD_DIR="$HOME/.config/nvim"
if [[ ! -d $NVCHAD_DIR ]]; then
  git clone https://github.com/NvChad/starter.git "$NVCHAD_DIR"
  # Plugins headless installieren und dann beenden
  nvim --headless +PackerSync +qa
else
  echo "→ NvChad existiert schon, update…"
  git -C "$NVCHAD_DIR" pull --ff-only
  nvim --headless +PackerSync +qa
fi

echo "6) Oh My Zsh installieren/konfigurieren…"
if [[ -d $HOME/.oh-my-zsh ]]; then
  echo "→ Oh My Zsh ist schon installiert."
else
  # non-interaktiv installieren, dann zsh als Standard-Shell setzen
  RUNZSH=no CHSH=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi


xfce4-panel --restart
echo "✓ Alles erledigt!"

