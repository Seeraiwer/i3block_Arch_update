# arch-update i3blocks script (bash)

Script bash pour i3blocks permettant d'afficher le nombre de mises a jour disponibles sur Arch Linux (paquets officiels + AUR). Il expose aussi un mode `update` pour lancer la routine de mise a jour.

---

## Dependances

- Bash
- [`checkupdates`](https://wiki.archlinux.org/title/Pacman/Tips_and_tricks#Listing_all_packages_to_be_upgraded) (fourni par `pacman-contrib`)
- [`yay`](https://github.com/Jguer/yay) (optionnel, pour l'AUR)
- [`pamac`](https://wiki.archlinux.org/title/Pamac) (optionnel, si tu veux l'utiliser)
- `eos-rankmirrors` (optionnel)
- `python3` + `pip` (optionnel, pour la mise a jour pip)
- `timeout` (optionnel, pour eviter les blocages)

---

## Integration i3blocks

Ajoute dans ton `~/.config/i3/i3blocks.conf` :

```ini
[pacman-updates]
command=~/.config/i3/scripts/update
interval=3600
LABEL=
QUIET=1
TIMEOUT=30
```

Le script imprime toujours 3 lignes (full_text, short_text, color) pour i3blocks.

---

## Variables d'environnement

- `LABEL` : icone affichee (defaut: ``)
- `QUIET=1` : si 0 MAJ, affiche seulement "OK"
- `TIMEOUT=30` : timeout (secondes) pour `checkupdates` et `yay -Qum`
- `NOCONFIRM=1` : ajoute `--noconfirm` a `yay`

---

## Usage

```bash
update status   # affiche le nombre de MAJ (pour i3blocks/polybar)
update update   # lance eos-rankmirrors, yay, pamac et pip
```

---

## Notes

- Si `yay` est absent, le script ignore simplement l'AUR.
- Si une commande est absente, le script continue en affichant un message clair.
