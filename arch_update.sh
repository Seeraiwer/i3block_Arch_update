#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_NAME="$(basename "$0")"

# ——————————————————————————————
# Compte les mises à jour pacman (officielles) et AUR
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

count_updates() {
    local official=0 aur=0 total=0
    local timeout_s="${TIMEOUT:-30}"

    if has_cmd checkupdates; then
        official=$( (LC_ALL=C run_with_timeout "$timeout_s" checkupdates 2>/dev/null | wc -l) || true )
        official=${official//[^0-9]/}
        official=${official:-0}
    fi

    if has_cmd yay; then
        aur=$( (LC_ALL=C run_with_timeout "$timeout_s" yay -Qum 2>/dev/null | wc -l) || true )
        aur=${aur//[^0-9]/}
        aur=${aur:-0}
    fi

    total=$(( ${official:-0} + ${aur:-0} ))
    echo "$total"
}

# ——————————————————————————————
# Affichage pour i3blocks / polybar
status() {
    local total color
    local label="${LABEL:-}"
    local quiet="${QUIET:-0}"
    total=$(count_updates)

    if [ "$total" -eq 0 ]; then
        if [ "$quiet" = "1" ]; then
            echo "OK"
            return
        fi
        color="#00AF00"
    else
        color="#fb4934"
    fi

    # Trois lignes : full_text, short_text, color (même si 0)
    echo "$label  $total"
    echo "$label  $total"
    echo "$color"
}

# ——————————————————————————————
# Routine complète de mise à jour (appelée par option « update »)
perform_updates() {
    local noconfirm_flag=""
    if [ "${NOCONFIRM:-0}" = "1" ]; then
        noconfirm_flag="--noconfirm"
    fi

    echo "🛰  Mise à jour des miroirs…"
    if has_cmd eos-rankmirrors; then
        eos-rankmirrors || echo "⏩ Échec des miroirs, on continue…"
    else
        echo "⏩ eos-rankmirrors absent, on continue…"
    fi

    echo "🔄 Mise à jour des paquets AUR & officiels…"
    if has_cmd yay; then
        sudo yay -Syyu $noconfirm_flag || echo "⏩ Échec yay, on continue…"
    else
        echo "⏩ yay absent, on continue…"
    fi

    echo "📦 Mise à jour pamac…"
    if has_cmd pamac; then
        sudo pamac upgrade -y || echo "⏩ Échec pamac, on continue…"
    else
        echo "⏩ pamac absent, on continue…"
    fi

    echo "🐍 Mise à jour pip…"
    if has_cmd python3; then
        sudo python3 -m pip install --upgrade pip --break-system-packages \
            || echo "⏩ Échec pip, on continue…"
    else
        echo "⏩ python3 absent, on continue…"
    fi
}

# ——————————————————————————————
usage() {
    cat <<EOF
Usage : $SCRIPT_NAME [status|update]

  status            Affiche le nombre de MAJ (pour i3blocks/polybar)
  update            Lance eos-rankmirrors, yay, pamac et pip
  -h, --help        Affiche cette aide

Variables d'environnement :
  LABEL=          Icône affichée (défaut : clé)
  QUIET=1          Si 0 MAJ, affiche seulement "OK"
  TIMEOUT=30       Timeout (secondes) pour checkupdates/yay -Qum
  NOCONFIRM=1      Ajoute --noconfirm à yay
EOF
    exit 1
}

# ——————————————————————————————
# Point d’entrée
case "${1:-status}" in
    status)
        status
        ;;
    update)
        perform_updates
        ;;
    -h|--help)
        usage
        ;;
    *)
        echo "❌ Option inconnue : '$1'"
        usage
        ;;
esac
