---
name: git-commit-push
description: Stage, commit (Conventional Commits format with emoji prefix), and push pending changes to the current branch's upstream. Use for repetitive "add + commit + push" wrap-up requests.
argument-hint: "[message optionnel]"
---

Stage, commit, and push the pending changes in the current git repo.

1. `git status` + `git diff` (staged and unstaged) to see what changed. Stage files by name - never `git add -A` / `git add .`.
2. If any file looks like it could hold secrets (`.env`, credentials, keys), stop and warn instead of committing.
3. Commit message: Conventional Commits (`type: short description`), prefixed with an emoji matching the type. Use `$ARGUMENTS` if given; else infer type and description from the diff. One line unless more context is essential. Emoji mapping:
   - `feat` → ✨
   - `fix` → 🐛
   - `docs` → 📝
   - `style` → 🎨
   - `refactor` → ♻️
   - `perf` → ⚡️
   - `test` → ✅
   - `chore` → 🔧
   - `build` / deps → ⬆️
   - `ci` → 👷
   - `revert` → ⏪
   Format: `<emoji> type: short description`
4. Commit via heredoc:
   ```
   git commit -m "$(cat <<'EOF'
   <emoji> <type>: <message>

   EOF
   )"
   ```
5. `git push` (or `git push -u origin <branch>` if no upstream). Never force-push, never skip hooks, never amend.
6. If the push is rejected (e.g. non-fast-forward), stop and ask how to proceed - do not force-push.
7. Confirm with `git log -1 --oneline` and report the commit hash and branch pushed, displaying the exact commit message as written (with its emoji).
