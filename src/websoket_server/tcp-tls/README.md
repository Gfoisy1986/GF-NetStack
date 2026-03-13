# TCP + TLS (Secure Server & Client)

Ce module fournit un serveur et un client TCP sécurisés via TLS (OpenSSL).  
Il utilise les wrappers C du dossier `net/` pour gérer le chiffrement, les sockets sécurisés et les échanges cryptés.

## Contenu
- `server/` : Serveur TLS
- `client/` : Client TLS

## Fonctionnalités
- Connexion sécurisée via TLS
- Envoi et réception de données chiffrées
- Intégration avec OpenSSL
- Base idéale pour des API sécurisées ou des agents distants

## Objectif
Proposer une fondation TLS simple et stable, pouvant servir à des protocoles JSON, des agents sécurisés ou des services réseau nécessitant du chiffrement.
