# RTK - dépannage

Fichier consulté à la demande uniquement (non injecté dans le contexte des agents). Voir
`RTK.md` pour l'usage courant.

## Vérifier l'installation

```bash
rtk --version   # doit afficher : rtk X.Y.Z
rtk gain        # doit fonctionner, et non « command not found »
which rtk       # vérifier que c'est le bon binaire
```

## Collision de nom

Si `rtk gain` échoue, un autre binaire `rtk` est probablement installé :
reachingforthejack/rtk (Rust Type Kit), sans rapport avec Rust Token Killer. Comparer la
sortie de `which rtk` avec le chemin d'installation attendu.
