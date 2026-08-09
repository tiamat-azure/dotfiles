---
name: init-agent
description: Generate or audit a project's AGENTS.md (context file for coding agents) following best practices - concise, structured, progressive disclosure - and ensure CLAUDE.md symlinks to it, never duplicates it. Use when starting a new project without AGENTS.md, or reviewing/improving an existing one.
argument-hint: '[project path, default: current directory]'
---

Help the user write (or audit) a high-quality `AGENTS.md` at the project root, then wire
the `CLAUDE.md` symlink.

Target project: `$ARGUMENTS` if given, else current working directory.

## 1. Gather context

Never invent content. If `AGENTS.md` (or `CLAUDE.md`) already exists, read it first -
audit/refresh, not a rewrite from scratch. Then inspect the repo directly (`ls`,
`package.json` / `pyproject.toml` / `Makefile` / CI config, existing tests) to answer:

- **WHAT**: tech stack, project layout (key files/dirs, critical in a monorepo).
- **WHY**: purpose of the project and its main parts.
- **HOW**: build/lint/test/format commands, workflow conventions, verification steps.
- Repo-specific code conventions (style, dependencies to avoid, module boundaries).
- Known pitfalls (surprising behavior, past mistakes, invariants to preserve).

If something isn't discoverable from the repo, ask the user directly rather than guessing.
Don't ask about things you can verify yourself by reading files.

## 2. Write AGENTS.md

Start from `template/AGENTS.md` in this skill's directory and adapt it with what you
learned in step 1 - it's a skeleton, not boilerplate to leave unfilled.

Apply these rules while writing:

- Cover WHAT / WHY / HOW - nothing else.
- **Concision**: target under 300 lines, ideally under 60. Past ~150-200 instructions,
  adherence degrades uniformly across the whole file, not just the newest additions.
- The model attends more to the start and end of the file - keep both informative, no
  filler.
- **Progressive disclosure**: move bulky detail (data schema, deep architecture,
  deployment steps) to separate files (e.g. `agent_docs/`); the root file just lists them
  with a one-line description.
- **Pointers, not copies**: reference `file:line` instead of duplicating content that will
  go stale.
- **Nothing superfluous**: only include what applies to every task in this repo. No
  one-off "hotfix" instructions. Don't replace a linter/formatter with prose rules - point
  to the deterministic tooling instead.
- **Always write `AGENTS.md` in English**, regardless of the repo's dominant language or
  the language used elsewhere in the conversation.

## 3. Symlink CLAUDE.md -> AGENTS.md

`CLAUDE.md` must never be a separate file or a copy. Once `AGENTS.md` is written:

```bash
cd <project-root>
rm -f CLAUDE.md   # only if it's a regular file (never if it holds info missing from AGENTS.md - merge first in that case)
ln -s AGENTS.md CLAUDE.md
```

If `CLAUDE.md` already existed as a regular file with divergent content, merge that
content into `AGENTS.md` first (respecting the rules above) - never lose information
silently.

## 4. Report

Confirm to the user: path of `AGENTS.md`, its line count, and that `CLAUDE.md` is now a
symlink (`ls -la CLAUDE.md`). Point out anything you deliberately left out of `AGENTS.md`
for concision, so the user can ask for it back if needed.
