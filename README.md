# **fortran-net**  
### **Fortran + C Wrappers for TCP, TLS, WebSocket & Future HTTPS/WSS Servers**

`fortran-net` est une couche réseau moderne qui combine la puissance du C (sockets, TLS, WebSocket) avec la propreté et la stabilité du Fortran.  
Le projet fournit une base modulaire pour construire :

- serveurs TCP  
- serveurs TLS sécurisés  
- serveurs WebSocket (WSS)  
- serveurs HTTP/HTTPS  
- tunnels chiffrés  
- agents distants  
- protocoles JSON personnalisés  

L’objectif long terme : devenir l’infrastructure réseau sécurisée pour les outils GF‑Meca (tunnels admin, agents distants, dashboards web).

---

# 🚀 **Fonctionnalités actuelles**

## ✔ C Wrappers (TCP + TLS)
- `tcp_wrapper.c` : sockets brutes (listen, accept, connect, send, recv)
- `tls_wrapper.c` : encapsulation OpenSSL (SSL_accept, SSL_connect, SSL_read, SSL_write)
- Multi‑client sécurisé (un SSL par connexion)
- Compatible Linux & Windows (MSYS2)

## ✔ Modules Fortran
- `tcp.mod` : interface Fortran pour TCP
- `tls_module.mod` : interface Fortran pour TLS
- `router.mod` : routage JSON (TLS server)
- `websocket.mod` : en développement (handshake + frames texte/binaire)

## ✔ Programmes Fortran fonctionnels
- `tls_server.f90` : serveur JSON‑over‑TLS multi‑sessions
- `tls_client.f90` : client TLS persistant
- Build propre via `make`

## ✔ Communication TLS complète
- Handshake OK  
- JSON échangé en Fortran ↔ C ↔ OpenSSL  
- Multi‑client stable  

---

# 🧱 **Architecture**

```
Fortran Servers (TLS / WSS / HTML)
        │
        ▼
Fortran Modules (ISO_C_BINDING)
        │
        ▼
C Wrappers (TCP / TLS / WebSocket)
        │
        ▼
System Sockets + OpenSSL
```

Cette architecture garde Fortran propre, moderne et modulaire.

---

# 🌐 **Serveurs prévus**

## 🔹 **1. TLS Server (déjà fonctionnel)**
- JSON‑over‑TLS  
- tunnel sécurisé  
- multi‑client  
- routage via `router.mod`

## 🔹 **2. WSS Server (en développement)**
- WebSocket sécurisé (WSS)
- support texte (opcode 0x1)
- support binaire (opcode 0x2)
- handshake WebSocket
- streaming temps réel

## 🔹 **3. HTML/HTTPS Server (à venir)**
- servir `/www/index.html`
- API REST
- intégration dashboard GF‑Meca

---

# 🔐 **Génération des certificats TLS**

Les certificats ne sont pas inclus dans le repo.  
Génère `server.pem` et `server.key` :

## Linux
```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout server.key \
  -out server.pem \
  -days 365 \
  -nodes \
  -subj "/CN=localhost"
```

## Windows (PowerShell)
```powershell
openssl req -x509 -newkey rsa:2048 `
  -keyout server.key `
  -out server.pem `
  -days 365 `
  -nodes `
  -subj "/CN=localhost"
```

---

# 🛠️ **Compilation**

## Linux
```bash
sudo apt install gcc gfortran make openssl libssl-dev
make
```

## Windows (MSYS2)
```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-openssl
make
```

---

# 🧪 **Exécution**

```bash
./build/tls_server
./build/tls_client
```

---

# 📦 **Modules Fortran — Aperçu**

## `tcp.mod`
- `tcp_listen_f`
- `tcp_accept_f`
- `tcp_connect_f`
- `tcp_send_f`
- `tcp_recv_f`
- `tcp_close_f`

## `tls_module.mod`
- `tls_init_server_f`
- `tls_init_client_f`
- `tls_listen_f`
- `tls_accept_f`
- `tls_connect_f`
- `tls_send_f`
- `tls_recv_f`
- `tls_close_f`

## `websocket.mod` (en développement)
- `ws_handshake_f`
- `ws_read_frame_f`
- `ws_send_text_f`
- `ws_send_binary_f`

---

# 🎯 **Vision du projet**

### 🔐 1. Backbone sécurisé GF‑Meca  
Tunnel TLS + WebSocket pour agents distants.

### 🌐 2. Dashboard web  
HTML + WSS pour monitoring en temps réel.

### 📦 3. JSON Protocol  
- auth  
- system_info  
- file operations  
- logs  
- remote commands  

### 🧩 4. Serveurs modulaires  
- `html_server`  
- `wss_server`  
- `tls_server`  

---

# 🛣️ **Roadmap**

### ✔ WebSocket : frames texte + binaire  
### ✔ WSS server minimal  
### ⬜ HTTP/HTTPS server  
### ⬜ Router JSON complet  
### ⬜ Dashboard web  
### ⬜ Multi‑client avancé (select/poll)  
### ⬜ Packaging & déploiement  

---

Guillaume Foisy
