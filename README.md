# **GF‑Network‑Tools**
Un ensemble d’outils réseau modulaires écrits en **Fortran** avec des **wrappers C**, conçus pour construire des serveurs et clients modernes : TCP, TLS et WebSocket.  
Le projet met l’accent sur une architecture claire, modulaire et extensible, inspirée des environnements de développement simples comme PureBasic, mais avec la puissance et la performance du backend Fortran/C.

---

## 🚀 **Vision du projet**
GF‑Network‑Tools vise à offrir :

- **Un backend réseau moderne en Fortran**, propre et portable  
- **Des modules indépendants** pour TCP, TLS et WebSocket  
- **Une API simple à utiliser**, façon `OpenNetworkConnection()`  
- **Une architecture claire**, facile à maintenir et à étendre  
- **Des wrappers C minimalistes**, pour combler les limites du standard Fortran  
- **Une base solide pour des serveurs, agents et applications réseau**  

L’objectif final : fournir une boîte à outils complète pour créer des serveurs et clients robustes, sécurisés et performants — sans complexité inutile.

---

## 📁 **Structure actuelle du projet**
Le dépôt est en cours de restructuration pour séparer clairement les couches :

```
net/        → Backend bas niveau (TCP, TLS, crypto, wrappers C)
ws/         → Serveur & client WebSocket (WSS)
tcp/        → Serveur & client TCP
tcp-tls/    → Serveur & client TCP+TLS
```

Chaque section aura son propre README détaillé plus tard.

---

## 🧩 **État actuel**
- Serveur WebSocket (WSS) fonctionnel  
- Client réseau propre en développement  
- Backend TCP/TLS stable  (nouvelle version en cour)
- Nettoyage et réorganisation du dépôt en cours  
- API haut niveau en réflexion (`OpenNetworkConnection()`, etc.)

---

## 🛠️ **Technologies**
- **Fortran 95+**  
- **C Wrappers** (TCP, TLS, Crypto)  
- **OpenSSL** (TLS, SHA‑1, Base64)  
- **Select()** pour la gestion multi‑clients  
- **WebSocket RFC 6455** (handshake + framing)

---

## 📌 **Objectif à court terme**
Finaliser la structure du dépôt et stabiliser les modules :

- `ws/` pour WebSocket  
- `tcp/` pour TCP  
- `tcp-tls/` pour TLS  
- `net/` comme moteur interne  

Ensuite : création d’une API simple et propre pour les développeurs.

---

Guillaume Foisy
