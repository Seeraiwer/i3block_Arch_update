# 🩻 arch-update i3blocks script

Script Python pour i3blocks permettant d'afficher les mises à jour disponibles sur Arch Linux, incluant les paquets AUR.
Inspiré de https://github.com/snowiow/i3blocks-contrib/blob/master/arch-update/arch-update.py

Compatible avec `markup=pango` pour une sortie enrichie, personnalisable via des variables d'environnement ou des arguments. Supporte les regex de surveillance, les helpers modernes (`yay`), et gère proprement les erreurs.

---

## 📦 Dépendances

- [`checkupdates`](https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Listing_all_packages_to_be_upgraded) (fourni par `pacman-contrib`)
- [`yay`](https://github.com/Jguer/yay) (ou tout helper AUR compatible avec `yay -Qum`)
- Python 3.6+

---

## 🧩 Intégration i3blocks

Ajoutez dans votre `~/.config/i3/i3blocks.conf` :

```ini
[pacman-updates]
command=~/.config/i3/scripts/arch-update
interval=3600
markup=pango
QUIET=true
WATCH=^linux.* ^pacman.*
BASE_COLOR=#5fff5f
UPDATE_COLOR=#FFFF85
AUR=true
LABEL= 
