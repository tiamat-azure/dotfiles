# Project decisions for agents

The following decisions are intentional. Do NOT silently revert them.

- The `ll` alias (`shellAliases` in `home.nix`) intentionally uses `ls -lao` instead of `ls -la`: the `-o` flag suppresses the group column to keep output concise. Do not revert to `-la`.

## Maintaining this file

Keep this file limited to information that is useful across nearly all future agent sessions.
Do not duplicate information already present in the codebase; instead, reference the authoritative file or command.
When updating this file, prefer revising or removing existing entries over appending new ones.
Keep this section intact and keep all entries concise.

