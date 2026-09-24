# AGENTS.md

Guidance for AI coding agents working in this repo.

## Repo

Nix + home-manager dotfiles (standalone, no NixOS/nix-darwin), for Ubuntu 26, user
`2456bru`. Full narrative in `README.md`.

## Commands

```sh
./rebuild.sh                 # apply: symlinks repo to ~/.dotfiles, runs `home-manager switch`
nix flake check --no-build   # validate without applying
```

Flakes only see git-tracked content - `git add <file>` (staging suffices) before
rebuild/check or it errors "not tracked by Git". No test suite; `nix flake check` is the
closest to CI.

Interactively, the `rebuild` shell alias (`~/.dotfiles/rebuild.sh && sourcez`) reloads the
current shell afterward, so new aliases/functions are usable immediately - a script run as
a subprocess can't otherwise touch the parent shell's environment.

Always commit changes made in this repo (without pushing, unless asked otherwise) so the
user can `./rebuild.sh` and test them.

## Architecture

- `flake.nix`: declares `homeConfigurations` per machine, all built from `home.nix`
  parameterized by `username`/`desktop`. `desktop=true` (`2456bru`) adds GNOME/GUI
  (WezTerm/nixGL, dconf, systemd services); `desktop=false` (`tiamat`, WSL2) is CLI-only.
  `rebuild.sh` auto-picks the config matching `id -un`.
- `home.nix`: single source for packages, shell (zsh/starship), dotfile placement - two
  patterns, don't conflate:
  - **Edit-in-place symlinks** (`mkOutOfStoreSymlink`) point back into this repo - editing
    the live path (`~/.config/wezterm`, `~/.config/nvim`, `~/.claude/settings.json`...)
    edits the repo directly, no rebuild needed.
  - **Generated** (packages, dconf, services) need `./rebuild.sh`.
- `home/`: files symlinked into place, mirrors `$HOME` layout (e.g.
  `home/.config/wezterm/wezterm.lua` -> `~/.config/wezterm/wezterm.lua`).
- `pkgs/`: custom derivations absent from nixpkgs (e.g. `openwhispr.nix`, AppImage via
  `appimageTools`).
- `home/AGENTS.md`: separate file - the *global* agent policy, symlinked to
  `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.config/opencode/AGENTS.md`, applied
  machine-wide to every project. Not this file.

## Notes

- **nixGL**: Nix-built GUI apps can't find the system OpenGL/EGL driver off NixOS. WezTerm
  is wrapped through `nixgl.packages.${system}.nixGLIntel` in `home.nix`; swap vendor
  there if needed.
- **rtk**: token-saving proxy CLI, auto-rewrites agent shell commands (`git status` ->
  `rtk git status`) via hook - nothing to invoke manually. Usage: `home/.claude/RTK.md`
  (`@`-imported in `home/AGENTS.md`). Troubleshooting:
  `home/.claude/rtk-troubleshooting.md` (not `@`-imported, reference by path only if rtk
  misbehaves).
- **cclog** (alias, `home/.claude/scripts/show-session-log.sh`): pretty-prints a Claude
  Code session's tool_use/tool_result transcript from its `.jsonl` log; defaults to the
  most recent session for the current project, or `-f <file>` for an explicit one. Parses
  Claude Code's own session schema (`message.content[].type == tool_use|tool_result`) -
  not a standard format, not reusable as-is for other agents (Codex, Copilot CLI, etc.
  each log differently).
- **ccstats** (alias, `home/.claude/scripts/claude-usage-stats.sh`): agrège les stats de
  tokens/tool calls des sessions Claude Code (`~/.claude/projects/**/*.jsonl`), ventilées
  par modèle, chiffres formatés en k/M.
- **Agents CLI tiers** (`home.activation` dans `home.nix`, pas des paquets nixpkgs) :
  - `grok` (xAI) : npm `@xai-official/grok`, réinstallé à chaque switch avec les CLIs AXI.
    Config `~/.grok/config.toml`, auth navigateur au premier lancement (ou `XAI_API_KEY`),
    abonnement SuperGrok / X Premium+ requis.
  - Ces paquets npm sont posés avec `--prefix ~/.local`, jamais dans le préfixe global de
    nvm : celui-ci dépend de la version node active, qui diffère entre l'activation (PATH
    propre, donc alias `default`) et les shells de l'utilisateur (nvm garde la version
    héritée du PATH de session). Un `npm install -g` nu atterrit dans un préfixe invisible
    depuis le terminal.
  - `agent` (Cursor CLI, alias `cursor-agent`) : installeur `cursor.com/install`, joué
    seulement si `~/.local/bin/agent` manque (il re-télécharge ~100 Mo sinon). Mise à jour
    manuelle : `agent update`.
- **Unity / libxml2** : les éditeurs Unity 6000.6+ exigent `libxml2.so.2`, absent d'Ubuntu
  26.04. L'activation `unityLibxml2` (desktop) pose un lien vers `libxml2_13` dans chaque
  `~/Unity/Hub/Editor/*/Editor` (RUNPATH `$ORIGIN`). Nouvel éditeur installé via Hub :
  relancer `./rebuild.sh`.
- **PATH d'activation**: les blocs `home.activation` tournent avec un PATH réduit à
  quelques dérivations du store (pas de `/usr/bin`). `nvm.sh` s'y source sans erreur mais
  son auto-use échoue en silence faute d'`awk`, et le bloc npm devient un no-op - d'où le
  `export PATH` explicite en tête de `installAgentTools`. Toute activation qui appelle un
  outil hors nixpkgs doit faire pareil.
