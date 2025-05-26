#!/usr/bin/env python3
# Inspiré par https://github.com/snowiow/i3blocks-contrib/blob/master/arch-update/arch-update.py
# Script unifié pour i3blocks : détecte les mises à jour officielles et AUR,
# avec fallback rapide si l'environnement Python n'est pas optimal.
import os
import re
import subprocess
import sys
from typing import List, Set

def parse_env_flag(name: str, default: bool = False) -> bool:
    val = os.getenv(name)
    if val is None:
        return default
    return val.lower() in {"1", "true", "yes", "y"}

def get_env(key: str, default: str = "") -> str:
    return os.getenv(key, default)

def run_command(cmd: List[str], ignore_codes: Set[int]) -> List[str]:
    try:
        result = subprocess.run(
            cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
            text=True, check=True
        )
        return [line.split()[0] for line in result.stdout.splitlines() if line.strip()]
    except subprocess.CalledProcessError as e:
        if e.returncode in ignore_codes:
            return []
        print(f"Erreur lors de l'exécution de {' '.join(cmd)}: {e}", file=sys.stderr)
        return []
    except FileNotFoundError:
        return []

def get_pacman_updates() -> List[str]:
    return run_command(["checkupdates"], ignore_codes={2})

def get_aur_updates() -> List[str]:
    return run_command(["yay", "-Qum"], ignore_codes={1})

def filter_updates(updates: List[str], patterns: List[str]) -> Set[str]:
    return {u for u in updates if any(re.match(p, u) for p in patterns)}

def print_simple_output(count: int):
    icon = get_env("LABEL", "")  # icône par défaut :  = wrench
    print(f"{icon} {count}")
    print(f"{icon} {count}")
    print("#fb4934")  # rouge doux

def print_pango_output(count: int, updates: List[str], patterns: List[str]):
    base_color = get_env("BASE_COLOR", "green")
    update_color = get_env("UPDATE_COLOR", "yellow")
    label = get_env("LABEL", "")
    quiet = parse_env_flag("QUIET", False)

    if count > 0:
        matched = filter_updates(updates, patterns) if patterns else set()
        plural = 's' if count > 1 else ''
        msg = f"{count} mise{plural} à jour disponible"
        if matched:
            msg += f" [{', '.join(sorted(matched))}]"
        print(f"{label}<span color='{update_color}'>{msg}</span>")
        print(f"{label}<span color='{update_color}'>{count}{'*' if matched else ''}</span>")
    elif not quiet:
        print(f"{label}<span color='{base_color}'>Système à jour</span>")


def main():
    try:
        use_pango = get_env("MARKUP", "pango") == "pango"
        patterns = get_env("WATCH", "").split()
        include_aur = parse_env_flag("AUR", False)

        pacman = get_pacman_updates()
        aur = get_aur_updates() if include_aur else []
        updates = pacman + aur
        count = len(updates)

        if use_pango:
            print_pango_output(count, updates, patterns)
        else:
            if count > 0:
                print_simple_output(count)
            elif not parse_env_flag("QUIET", False):
                print("OK")
    except Exception as e:
        print(f"Erreur: {e}", file=sys.stderr)
        print("X")

if __name__ == "__main__":
    main()
