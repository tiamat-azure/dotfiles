# dotfiles

![landscape](images/landscape.png)

Inspired by [Kun Chen's Mac dotfiles walkthrough](https://youtu.be/5N-okeDdIuI), adapted
for **Ubuntu 26** (not NixOS) using standalone
[home-manager](https://nix-community.github.io/home-manager/).

One repo, one command, and the machine ends up configured the same way every time.

## What you get

Running the switch builds:

- Nix user packages: `ripgrep`, `fd`, `bat`, `htop`, `fzf`, `jq`, `lazygit`, `neovim`,
  `wezterm`, `Hack Nerd Font`, `OpenWhispr`
- Terminal (WezTerm, edit-in-place config, rose-pine moon theme) — wrapped through
  [nixGL](https://github.com/nix-community/nixGL) since Nix packages can't find the
  system's OpenGL/EGL driver outside NixOS
- GNOME desktop settings via `dconf` (dark mode, fast key repeat, tap-to-click, dock
  auto-hide, list view in Nautilus) — the closest equivalent to nix-darwin's
  `system.defaults` on this OS
- `$EDITOR` set to `nvim`
- Agent config template (`AGENTS.md`)

**Not included** (unlike the Mac version this is adapted from): no system-level config
(there's no nix-darwin/NixOS layer here — Ubuntu itself stays in charge of the OS), no
Homebrew equivalent, no shell/prompt config yet.

## Prerequisites

- Ubuntu (x86_64) installed
- Flakes enabled — add to `~/.config/nix/nix.conf`:
  ```
  experimental-features = nix-command flakes
  ```
- An Intel/Mesa GPU, as configured. Other vendors need one line changed — see "Make it
  yours".

## Fresh-machine setup

There's no bootstrap script here (unlike the Mac version) since there's no system layer or
Homebrew to provision — just Nix + this repo.

```sh
git clone https://github.com/tiamat-azure/dotfiles.git ~/workspaces/dotfiles
cd ~/workspaces/dotfiles
```

Before the first run, review "Make it yours" below (username, GPU vendor).

```sh
./rebuild.sh
```

`rebuild.sh` does two things:

1. Symlinks this repo to `~/.dotfiles`, wherever it was cloned. `home.nix` points at
   config files through `~/.dotfiles`, so this has to happen before the symlinked configs
   (WezTerm) resolve correctly.
1. Runs `home-manager switch --flake ~/.dotfiles#<user>`.

### Validate without applying

```sh
nix flake check --no-build
```

**Note:** Nix flakes only read git-tracked file content. If you add or edit a file and the
build complains it's "not tracked by Git", run `git add <file>` first (staging is enough,
no need to commit).

## Daily use

Edit the config, then apply:

```sh
./rebuild.sh
```

WezTerm's config (`home/.config/wezterm/wezterm.lua`) is symlinked in place — edit it
directly, no rebuild needed to see the change.

In an interactive shell, use the `rebuild` alias instead of `./rebuild.sh` directly — it
runs the script then `source ~/.zshrc`, so new aliases/functions are usable right away in
the current terminal.

## Make it yours

This repo is configured for one machine and one user (`2456bru`). If you clone it:

- **Username**: change it in **two places** — `user = "2456bru"` in `flake.nix`, and
  `home.username` / `home.homeDirectory` in `home.nix`. Also update the `#2456bru` at the
  end of `rebuild.sh`'s flake reference.
- **GPU vendor**: `home.nix` wraps WezTerm with `nixgl.packages.${system}.nixGLIntel`. If
  you're on Nvidia or AMD, swap it for the matching nixGL package (`nixGLNvidia`,
  `nixGLDefault`, etc. — see the [nixGL repo](https://github.com/nix-community/nixGL) for
  the full list).
- **Git identity**: not managed by this repo. Set it yourself with
  `git config --global user.name`/`user.email` (already done on this machine:
  `tiamat-azure`).
- **`AGENTS.md`**: currently a placeholder template, not filled in yet.

## Repo tour

- `flake.nix` — entry point. Wires up `nixpkgs`, `home-manager`, and `nixgl`, and declares
  the `homeConfigurations.2456bru` output.
- `home.nix` — user-level config: packages, `dconf` GNOME settings, the WezTerm/nixGL
  wrapper, and the symlink described below.
- `rebuild.sh` — symlinks the repo to `~/.dotfiles` and re-applies the config. Run this
  every time you make a change.
- `home/` — the real config files that get symlinked into place (currently just
  WezTerm's).
- `AGENTS.md` — agent policy template.
- `home/.claude/scripts/update-readme-stats.sh` — regenerates the stats block below (see
  "Stats block").

## Stats block

The "Statistiques d'usage Claude Code" section below is generated, not hand-edited.
Refresh it with `ccstats-readme` (alias for
`~/.claude/scripts/update-readme-stats.sh ~/.dotfiles/README.md`), which rewrites the
content between the `<!-- STATS:START -->` / `<!-- STATS:END -->` markers in place.

## How the symlink works

`home/.config/wezterm/wezterm.lua` is the real file — editing it here is editing your live
config. `home.nix` uses `mkOutOfStoreSymlink` to point `~/.config/wezterm` straight at
`home/.config/wezterm` in this repo, so the two never drift out of sync. You only need
`./rebuild.sh` for changes that aren't a symlinked file, like a package list or a `dconf`
setting.

<!-- STATS:START -->

<!-- Genere automatiquement par update-readme-stats.sh - ne pas editer a la main -->

## Statistiques d'usage Claude Code

_Cumul de toutes les sessions, tous projets - derniere mise a jour : 2026-08-22 10:26_

| Metrique              | Total  |
| --------------------- | ------ |
| Input tokens          | 242.3k |
| Output tokens         | 4.8M   |
| Cache read tokens     | 680.9M |
| Cache creation tokens | 32.9M  |
| Tool calls            | 6.4k   |

### Par modele

| Modele                    | Input  | Output | Cache read | Cache creation | Tool calls |
| ------------------------- | ------ | ------ | ---------- | -------------- | ---------- |
| claude-haiku-4-5-20251001 | 2.1k   | 21.3k  | 3.0M       | 259.4k         | 38         |
| claude-opus-5             | 130.6k | 1.4M   | 174.8M     | 6.2M           | 1.3k       |
| claude-sonnet-5           | 109.7k | 3.4M   | 503.1M     | 26.4M          | 5.1k       |

<!-- STATS:END -->

## License

MIT. See `LICENSE`.
