# **README.md — API (en développement)**


# API Layer (en développement)

La section **api/** accueillera une couche d’abstraction haut niveau destinée à simplifier l’utilisation du backend réseau du projet.  
L’objectif est d’offrir une interface moderne, propre et intuitive — inspirée de la simplicité de PureBasic — tout en s’appuyant sur la puissance du moteur Fortran/C situé dans `net/`.



L’idée est de masquer toute la complexité interne (TCP, TLS, WebSocket, crypto, wrappers C) derrière une interface simple et cohérente.

## 🌐 Vision : Une API Fortran moderne pour tous les services réseau

L’objectif long terme de la section **api/** est d’offrir une interface unifiée permettant d’accéder facilement à une grande variété de services réseau, sans exposer la complexité interne du backend TCP/TLS/WebSocket.

L’API deviendra une boîte à outils polyvalente, capable de supporter des protocoles standards utilisés dans le monde réel :

### 📬 Services de messagerie
- **POP3** — lecture de boîtes courriel
- **SMTP** — envoi de courriels
- **IMAP** — gestion avancée des messages
- **Submission (587/TLS)** — envoi sécurisé moderne

### 🌍 Services web & cloud
- **TCP/TLS sécurisé** — communications simples ou avancées avec chiffrement automatique
- **HTTP/HTTPS** — requêtes simples ou avancées
- **WebSocket (WS/WSS)** — communication temps réel
- **REST/JSON** — API modernes
- **GraphQL** (à long terme)

### 📡 Protocoles machine‑to‑machine
- **MQTT** — IoT, capteurs, automation
- **CoAP** — appareils légers
- **gRPC** (via wrappers C)

### 🗄️ Services de données
- **Redis** — cache, pub/sub
- **Memcached**
- **SQLiteCloud** (déjà en réflexion dans ton projet)
- **PostgreSQL/MySQL** (via wrappers)

### 🔐 Sécurité & chiffrement
- Gestion TLS simplifiée
- Validation de certificats
- Connexions sécurisées automatiques

---

## 🎯 But final
Créer une API Fortran moderne, simple et élégante, permettant d’écrire :



```fortran
conn = OpenNetworkConnection("example.com", 443, useTLS=.true.)
call SendString(conn, '{"cmd":"ping"}')
reply = ReceiveString(conn)
call CloseConnection(conn)
```

```fortran
conn = OpenNetworkConnection("mail.example.com", 995, useTLS=.true.)
call POP3_Login(conn, "user", "pass")
messages = POP3_List(conn)
call CloseConnection(conn)


---

Guillaume Foisy
