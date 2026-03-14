# Wrappers C & Fortran

Ce dossier contient les couches de “pont” entre les bibliothèques natives (C) et le code Fortran du SDK.

Les wrappers sont séparés en deux niveaux :

- `c/` : adaptation côté C
- `fortran/` : interfaces FFI côté Fortran

---

## c/ — Wrappers C

📁 `src/wrappers/c/`

Cette couche :

- encapsule les appels aux bibliothèques natives (dans `deps/`)
- normalise les signatures C
- masque les détails spécifiques aux plateformes
- expose une API C stable, pensée pour être appelée depuis Fortran

En résumé :  
**C’est la couche “adaptation native” entre `deps/` et Fortran.**

---

## fortran/ — Wrappers Fortran (FFI)

📁 `src/wrappers/fortran/`

Cette couche :

- définit les `interface ... bind(C)`
- mappe les types C ↔ Fortran
- gère les pointeurs, chaînes, tableaux
- appelle directement les fonctions définies dans `src/wrappers/c/`

En résumé :  
**C’est la passerelle FFI entre le monde C et les modules Fortran.**

---

## Relation avec le reste du SDK

Flux logique :

- `deps/` → bibliothèques natives (C, externes)
- `src/wrappers/c/` → adaptation C
- `src/wrappers/fortran/` → FFI Fortran
- `src/modules/` → logique Fortran regroupée
- `src/api/` → API haut niveau
- `src/core/` → apps/démos internes
- `examples/` → exemples simples pour les utilisateurs

Les wrappers ne doivent **pas** contenir de logique métier :  
ils servent uniquement à connecter proprement C ↔ Fortran.
