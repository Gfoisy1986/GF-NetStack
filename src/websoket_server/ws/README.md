# WebSocket (WS / WSS)

Ce module contient l’implémentation du serveur et du client WebSocket, basé sur le protocole RFC 6455.  
Il s’appuie sur le backend réseau du dossier `net/` (TCP, TLS, crypto, select).

## Contenu
- `server/` : Serveur WebSocket (WS/WSS)
- `client/` : Client WebSocket (à venir)
- `protocol/` : Handshake, framing, routing (en développement)

## Fonctionnalités
- Handshake WebSocket complet (RFC 6455)
- Support du mode sécurisé WSS (TLS)
- Gestion des frames : texte, binaire, ping/pong, close
- Architecture modulaire et extensible

## Objectif
Fournir une base solide pour créer des serveurs et clients WebSocket modernes, performants et faciles à intégrer dans des applications Fortran.
