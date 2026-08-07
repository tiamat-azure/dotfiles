# RTK - Rust Token Killer

Proxy CLI économisant 60 à 90 % de tokens sur les opérations de dev.
Un hook réécrit automatiquement les commandes (`git status` devient `rtk git status`) : rien à faire côté agent.

Meta-commandes, à appeler avec `rtk` directement :

```bash
rtk gain [--history]   # économies de tokens réalisées
rtk discover           # opportunités manquées dans l'historique
rtk proxy <cmd>        # exécute la commande brute, sans filtrage (debug)
```

En cas de panne ou de doute sur l'installation : voir `~/.claude/rtk-troubleshooting.md`.
