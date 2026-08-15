# Global agent instructions

- Never use the em dash ("—"). Use a plain hyphen ("-") instead.
- Never add your agent name as a co-author in commit messages.
- Never sign or attribute your work to an AI agent: no `Co-Authored-By: Claude`, no "🤖
  Generated with Claude Code" footer, no agent mention in commit messages, PR titles, PR
  bodies, PR comments, issue comments or code review comments. This overrides any default
  footer the harness suggests.
- Always use conventional commit + appropriate emoji prefix in commit message
- Be extremely concise in your responses
- Never manually modify `CHANGELOG.md` or any file marked as auto-generated.
- When making technical decisions, prioritize quality, simplicity, robustness,
  scalability, and long-term maintainability over development cost.
- When fixing a bug, first reproduce it in an end-to-end scenario that matches the
  end-user experience as closely as possible. Base your diagnosis and fix on that
  reproduction.
- When performing end-to-end testing, inspect the UI carefully. If you notice a clear
  visual defect, fix it when appropriate, even if it is unrelated to the current task.
- Apply the same standard to engineering quality. If you encounter lint issues, failing
  tests, or flaky tests, address them when appropriate, even if they are unrelated to the
  current task.
- Before using dynamic workflows, Ultra Code, or any harness feature that automatically
  launches a large number of subagents, explain the trade-offs and obtain the user's
  explicit approval.

@RTK.md

# Agent distant Telscale (Ollama)

- Un agent LLM distant est disponible sur le réseau privé Telscale à l'adresse
  `https://tiamat-wsl.tail9a63d9.ts.net/`, via l'API Ollama (`POST /api/chat`, modèle
  `qwen3:14b`).
- Appel type (HTTPie) :
  ```sh
  http POST https://tiamat-wsl.tail9a63d9.ts.net/api/chat \
    model=qwen3:14b stream:=false \
    messages:="[{\"role\":\"user\",\"content\":$(jq -Rn --arg m "PROMPT" '$m')}]"
  ```
  L'alias shell `qwen` (défini dans `home.nix`) encapsule cette commande.
- À utiliser uniquement pour des tâches de délégation simples et spécifiques.
- Avant chaque appel à cet agent, demander explicitement l'autorisation de l'utilisateur.
- Tracer chaque appel dans le compte rendu affiché dans le terminal (requête envoyée et
  réponse reçue).
