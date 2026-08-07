---
name: memorise
description: Review the current session and persist its durable facts to the project memory directory, then update MEMORY.md. Use at the end of a session, or when asked to "mémorise", "remember this session", "save what we learned".
argument-hint: "[sujet à mémoriser en priorité]"
---

Persist what is worth remembering from this session, and nothing else.

Memory is re-read into context at the start of every future session on this project: every line costs tokens forever. Write for the agent who will read it cold in six months, not for a session log.

Target directory: the project memory directory named in this session's memory instructions (typically `~/.claude/projects/<slugified-cwd>/memory/`). Write files directly - do not check whether the directory exists.

## 1. Select

Re-read the session. Keep a fact only if **all** of these hold:

- It stays true after this session ends.
- It is not recorded elsewhere the agent will already see: repo code, `git log`, `AGENTS.md` / `CLAUDE.md`, config files, tool output that is trivially re-runnable.
- It would change how a future session acts.

Drop: narration of what was done, resolved problems, intermediate reasoning, anything already in the diff. `$ARGUMENTS`, if given, names what to prioritise - it does not lower this bar.

Prioritise, in order: corrections the user made to how you work; user preferences and constraints; project state or decisions not derivable from the code; pointers to external resources.

## 2. Synthesise

One fact per file - but a *fact*, not a sentence. Several observations that are one idea belong in one file. Two unrelated ideas never share a file.

Before writing, check for an existing file covering the same ground: revise it in place rather than adding a near-duplicate. Delete files that this session proved wrong.

## 3. Write

```markdown
---
name: <short-kebab-case-slug>
description: <one line - this is the recall selector, so make it discriminating, not generic>
metadata:
  type: user | feedback | project | reference
---

<the fact, stated flat and complete. Link related memories with [[their-name]].>
```

- `feedback` and `project` files add a `**Why:**` line and a `**How to apply:**` line. Nothing else.
- Body target: under 5 lines. If it runs longer, it is probably two facts or a session log.
- Absolute dates only ("2026-08-05", never "hier", "la semaine dernière").
- No headings inside the body, no bullet lists restating one idea, no hedging.
- Link liberally with `[[name]]`; a link to a memory that does not exist yet is fine.

## 4. Index

Add or update one line per memory in `MEMORY.md`, in the same directory:

```
- [Titre](fichier.md) — accroche courte
```

`MEMORY.md` is loaded in full every session: index only, never content, no frontmatter, one line per file. Remove lines for deleted memories.

## 5. Report

List what was written, updated, and deleted - one line each. Then state plainly what you deliberately left out and why, so the user can overrule you.
