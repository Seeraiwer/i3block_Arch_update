#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"

# ——————————————————————————————
has_cmd() {
    command -v "$1" >/dev/null 2>&1
}

run_with_timeout() {
    local seconds="$1"
    shift
    if has_cmd timeout; then
        timeout "$seconds" "$@"
    else
        "$@"
    fi
}

aur_helper() {
    if has_cmd yay; then
        echo yay
    elif has_cmd paru; then
        echo paru
    fi
}

# ——————————————————————————————
# Compte les mises à jour pacman (officielles) et AUR
count_updates() {
    local official=0 aur=0
    local timeout_s="${TIMEOUT:-30}"
    local helper

    if has_cmd checkupdates; then
        official=$(LC_ALL=C run_with_timeout "$timeout_s" checkupdates 2>/dev/null | wc -l || true)
        official=${official//[^0-9]/}
        official=${official:-0}
    fi

    helper=$(aur_helper)
    if [[ -n "$helper" ]]; then
        aur=$(LC_ALL=C run_with_timeout "$timeout_s" "$helper" -Qum 2>/dev/null | wc -l || true)
        aur=${aur//[^0-9]/}
        aur=${aur:-0}
    fi

    echo $(( official + aur ))
}

# ——————————————————————————————
# Affichage pour i3blocks / polybar
status() {
    local total color
    local label="${LABEL:-}"
    local quiet="${QUIET:-0}"
    total=$(count_updates)

    if [[ "$total" -eq 0 ]]; then
        if [[ "$quiet" == "1" ]]; then
            echo "OK"
            return
        fi
        color="#00AF00"
    else
        color="#fb4934"
    fi

    # Trois lignes : full_text, short_text, color
    printf '%s  %s\n' "$label" "$total"
    printf '%s  %s\n' "$label" "$total"
    echo "$color"
}

# ——————————————————————————————
# Routine complète de mise à jour (appelée par option « update »)
perform_updates() {
    local -a pkg_flags=()
    [[ "${NOCONFIRM:-0}" == "1" ]] && pkg_flags+=(--noconfirm)
    local helper

    echo "🛰  Mise à jour des miroirs…"
    if has_cmd eos-rankmirrors; then
        eos-rankmirrors || echo "⏩ Échec des miroirs, on continue…"
    else
        echo "⏩ eos-rankmirrors absent, on continue…"
    fi

    echo "🔄 Mise à jour des paquets AUR & officiels…"
    helper=$(aur_helper)
    if [[ -n "$helper" ]]; then
        # yay/paru gèrent l'élévation de privilèges eux-mêmes — ne pas appeler avec sudo
        "$helper" -Syu "${pkg_flags[@]}" || echo "⏩ Échec $helper, on continue…"
    else
        echo "⏩ yay/paru absents — utilisation de pacman"
        sudo pacman -Syu "${pkg_flags[@]}" || echo "⏩ Échec pacman, on continue…"
    fi

    echo "📦 Mise à jour pamac…"
    if has_cmd pamac; then
        local -a pamac_flags=(-y)
        [[ "${NOCONFIRM:-0}" == "1" ]] && pamac_flags+=(--no-confirm)
        sudo pamac upgrade "${pamac_flags[@]}" || echo "⏩ Échec pamac, on continue…"
    else
        echo "⏩ pamac absent, on continue…"
    fi

    if [[ "${UPDATE_ENABLE_PIP:-0}" == "1" ]]; then
        echo "🐍 Mise à jour pip (UPDATE_ENABLE_PIP=1)…"
        if has_cmd python3; then
            sudo python3 -m pip install --upgrade pip --break-system-packages \
                || echo "⏩ Échec pip, on continue…"
        else
            echo "⏩ python3 absent, on continue…"
        fi
    else
        echo "⏩ pip ignoré (export UPDATE_ENABLE_PIP=1 pour activer)"
    fi
}

# ——————————————————————————————
usage() {
    cat <<EOF
Usage : $SCRIPT_NAME [status|update]

  status            Affiche le nombre de MAJ (pour i3blocks/polybar)
  update            Lance eos-rankmirrors, yay/paru, pamac et pip
  -h, --help        Affiche cette aide

Variables d'environnement :
  LABEL=               Icône affichée (défaut : vide)
  QUIET=1              Si 0 MAJ, affiche seulement "OK"
  TIMEOUT=30           Timeout pour checkupdates / yay|paru -Qum
  NOCONFIRM=1          --noconfirm pour yay/paru/pacman, --no-confirm pour pamac
  UPDATE_ENABLE_PIP=1  Inclut la mise à jour pip (déconseillé sur Python système)
EOF
    exit 1
}

# ——————————————————————————————
# Point d'entrée
case "${1:-status}" in
    status)    status ;;
    update)    perform_updates ;;
    -h|--help) usage ;;
    *)
        echo "❌ Option inconnue : '$1'"
        usage
        ;;
esac
