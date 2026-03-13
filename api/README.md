# **README.md — API (en développement)**

```markdown
# API Layer (en développement)

La section **api/** accueillera une couche d’abstraction haut niveau destinée à simplifier l’utilisation du backend réseau du projet.  
L’objectif est d’offrir une interface moderne, propre et intuitive — inspirée de la simplicité de PureBasic — tout en s’appuyant sur la puissance du moteur Fortran/C situé dans `net/`.

## 🎯 Vision
Fournir une API unifiée permettant d’écrire du code réseau clair et minimaliste, par exemple :

```fortran
conn = OpenNetworkConnection("example.com", 443, useTLS=.true.)
call SendString(conn, '{"cmd":"ping"}')
reply = ReceiveString(conn)
call CloseConnection(conn)
```

L’idée est de masquer toute la complexité interne (TCP, TLS, WebSocket, crypto, wrappers C) derrière une interface simple et cohérente.

## 🧱 Objectifs prévus
- Fonctions haut niveau pour ouvrir, envoyer, recevoir et fermer une connexion  
- Support transparent pour TCP, TLS et WebSocket  
- Gestion automatique des buffers et erreurs  
- API stable et portable, indépendante des détails internes  
- Documentation claire et exemples pratiques

## 🛠️ État actuel
La conception est en cours.  
La structure du dépôt est en train d’être finalisée avant l’implémentation de l’API.

## 🔮 À venir
- `OpenNetworkConnection()`
- `SendString()`
- `ReceiveString()`
- `CloseConnection()`
- Modules spécialisés pour WS, TCP et TLS
- Exemples complets d’utilisation

Cette section évoluera au fur et à mesure que le backend réseau sera stabilisé.
```

---

Guillaume Foisy
