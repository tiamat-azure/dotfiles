#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles

# La config appliquée est celle qui porte le nom de l'utilisateur courant
# (homeConfigurations.<user> dans flake.nix), donc un seul script pour toutes
# les machines.
flake="$HOME/.dotfiles#$(id -un)"

# -b backup : renomme au lieu d'échouer si un fichier géré existe déjà.
if command -v home-manager >/dev/null 2>&1; then
  exec home-manager switch -b backup --flake "$flake"
else
  # Tout premier build : home-manager n'est pas encore dans le profil.
  exec nix run home-manager/release-26.05 -- switch -b backup --flake "$flake"
fi
