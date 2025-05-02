#!/usr/bin/env bash
set -euo pipefail

# Farben für Fehlermeldungen
RED="$(tput setaf 1)"   || RED=""
RESET="$(tput sgr0)"     || RESET="

"
# Bei Strg+C oder Kill sauber aufräumen
cleanup() {
  echo            # Zeilenumbruch, falls der Cursor in der gleichen Zeile steht
  echo "${RED}X Skript manuell abgebrochen."
  # optional: Panel/Umgebung wiederherstellen
  xfce4-panel --restart
  exit 1
}
trap cleanup SIGINT SIGTERM

trap 'echo "${RED}X Fehler in Zeile $LINENO"; exit 1' ERR

# Logging
exec > >(tee -i setup.log) 2>&1

# Paketmanager-Detection
if command -v pacman &>/dev/null; then
  DISTRO="arch"
  PM_UP=(sudo pacman -Syu --noconfirm)
  PM_IN=(sudo pacman -S --needed --noconfirm)
#elif command -v dnf &>/dev/null; then
#  DISTRO="fedora"
#  PM_UP=(sudo dnf upgrade --refresh -y)
#  PM_IN=(sudo dnf install -y)
elif command -v apt-get &>/dev/null; then
  DISTRO="debian"
  PM_UPDATE=(sudo apt-get update)           # Paketlisten holen
  PM_UPGRADE=(sudo apt-get -y upgrade)     # System upgraden
  PM_IN=(sudo apt-get -y install)          # Installation
  sudo add-apt-repository ppa:neovim-ppa/unstable -y
else
  echo "Unsupported distro" >&2
  exit 1
fi

echo "1) Cache & Metadaten aktualisieren…"
if [[ $DISTRO == "debian" ]]; then
  "${PM_UPDATE[@]}"
  "${PM_UPGRADE[@]}"
else
  "${PM_UP[@]}"
fi

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
  fonts-jetbrains-mono flatpak wmctrl bat nala
)

#packages_fedora=(
#  zsh neovim git htop kitty qalculate xclip
#  libreoffice libreoffice-langpack-de flameshot gimp
#  thunderbird putty vlc gnome-disk-utility btop fzf hyfetch
#  gpick rpi-imager papirus-icon-theme unzip nomacs flatpak
#  bat 
#)
echo "3) Paktete installieren"
case "$DISTRO" in
  arch)   "${PM_IN[@]}" "${packages_arch[@]}" ;;
  fedora) "${PM_IN[@]}" "${packages_fedora[@]}" ;;
  debian) "${PM_IN[@]}" "${packages_debian[@]}" ;;
esac

echo "4) Flatpak & Flathub einrichten…"
sudo flatpak remote-add --if-not-exists flathub \
     https://flathub.org/repo/flathub.flatpakrepo

echo "5) Flatpak-Apps installieren…"
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
  echo "→ Klone NvChad…"
else
  echo "→ NvChad existiert schon, update…"
  git -C "$NVCHAD_DIR" pull --ff-only
fi

# Headless Plugin-Sync, stdin dicht, stdout+stderr nach /dev/null
if nvim --headless +PackerSync +qa! </dev/null &>/dev/null; then
  echo "→ Plugins synchronisiert"
else
  echo "${RED}X Plugin-Sync übersprungen (PackerSync nicht verfügbar)."
fi

echo "7) Oh My Zsh installieren/konfigurieren…"
if [[ -d $HOME/.oh-my-zsh ]]; then
  echo "→ Oh My Zsh ist schon installiert."
else
  # non-interaktiv installieren, dann zsh als Standard-Shell setzen
  RUNZSH=no CHSH=yes sh -c \
    "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi


xfce4-panel --restart
echo "✓ Alles erledigt!"

#alias vi="nvim"
#alias update="sudo pacman -Syu --noconfirm && flatpak update --appstream && flatpak update -y"
# fuzzy-kill: Prozess wählen und killen
#alias fkill='kill -9 "$(ps -ef | sed 1d | fzf | awk "{print \$2}")"'
# fuzzy-ssh: Host aus known_hosts wählen und verbinden
#alias fssh='ssh "$(awk -F"[ ,]" "{print \$1}" ~/.ssh/known_hosts | uniq | fzf)"'
