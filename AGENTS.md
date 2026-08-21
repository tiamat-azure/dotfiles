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
