#!/usr/bin/env bash
# Met à jour tout le système : paquets Nix (flake + home-manager), apt, snap,
# puis nettoie les vieilles générations Nix et pousse le flake.lock.
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
cd "$DIR"

step() { printf '\n\033[1;34m==> %s\033[0m\n' "$*"; }

# Demande le mot de passe sudo une seule fois, avant le long build Nix.
sudo -v

step "1/5 Nix : mise à jour du flake et home-manager switch"
nix flake update
./rebuild.sh
# Ne commite que flake.lock, sans embarquer d'autres modifs en cours.
if ! git diff --quiet -- flake.lock; then
  git commit -m "⬆️ chore(flake): update flake.lock" -- flake.lock
else
  echo "flake.lock inchangé"
fi

step "2/5 apt : mise à jour des paquets Ubuntu"
sudo apt update
sudo apt full-upgrade -y
sudo apt autoremove --purge -y

step "3/5 snap : mise à jour des snaps"
if command -v snap >/dev/null 2>&1; then
  sudo snap refresh
else
  echo "snap absent, étape ignorée"
fi

step "4/5 Nix : nettoyage des anciennes générations"
home-manager expire-generations "-30 days"
nix-collect-garbage -d

step "5/5 git : push des dotfiles"
if [ -n "$(git log --oneline '@{upstream}..HEAD')" ]; then
  git push
else
  echo "Rien à pousser"
fi

step "Terminé"
