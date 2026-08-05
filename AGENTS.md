# Project decisions for agents

The following decisions are intentional. Do NOT silently revert them.

- The `ll` alias (`shellAliases` in `home.nix`) intentionally uses `ls -lao` instead of `ls -la`: the `-o` flag suppresses the group column to keep output concise. Do not revert to `-la`.
- The repo is multi-machine: `flake.nix` exposes one `homeConfigurations.<user>` per machine via `mkHome { username, desktop }`. `2456bru` is the native Ubuntu desktop laptop (`desktop = true`); `tiamat` is a WSL2 box (`desktop = false`). GNOME/GUI blocks in `home.nix` (dconf, `xdg.desktopEntries`, the WezTerm/nixGL wrapper, `openwhispr`, the screenshot systemd service) are guarded by `lib.mkIf desktop` / `lib.optionals desktop` and MUST stay guarded — they break or are useless under WSL. `rebuild.sh` selects the config by `$(id -un)`.

## Maintaining this file

Keep this file limited to information that is useful across nearly all future agent sessions.
Do not duplicate information already present in the codebase; instead, reference the authoritative file or command.
When updating this file, prefer revising or removing existing entries over appending new ones.
Keep this section intact and keep all entries concise.

