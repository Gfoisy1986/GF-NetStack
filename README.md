# GF‑Fortran‑SDK 

## En cours de développement...  Currently in development...

### Fortran95 SDK — Bilingual README (FR/EN)

---

<details>
  <summary>🇫🇷 Version Française</summary>

# GF‑Fortran‑SDK  
### SDK moderne, modulaire et extensible pour Fortran95

GF‑Fortran‑SDK a pour ambition de devenir un **écosystème complet** pour développer des applications modernes en Fortran95.  
Le projet dépasse largement la simple notion “d’outils réseau” : il vise à offrir un **SDK modulaire, clair et extensible**, regroupant tout ce dont un développeur Fortran a besoin pour créer des applications réseau, graphiques et interactives.

---

## 🧱 Backend réseau moderne
- Modules indépendants : **TCP**, **TLS**, **WebSocket**  
- Wrappers C minimalistes pour contourner les limites du standard F95  
- Architecture propre, stable et maintenable  
- Gestion multi‑clients via `select()`  
- WebSocket conforme **RFC 6455**

---

## 🧩 API haut niveau intuitive
Inspirée de PureBasic, elle masque toute la complexité interne :

```fortran
conn = OpenNetworkConnection("example.com", 443, useTLS = .true.)
call SendString(conn, "ping")
reply = ReceiveString(conn)
```

---

## 🎨 Future API UI (f90GL)
Pour créer des interfaces modernes :  
Fenêtres, boutons, labels, sliders, layout automatique, intégration réseau.

---

## 🌐 Protocoles futurs
- HTTP / HTTPS  
- MQTT  
- CoAP  
- POP3 / SMTP / IMAP  
- Redis  
- Memcached  
- WebSocket avancé  
- Services cloud

---

## 🛠️ Environnement complet
- IDE spécialisé  
- Templates de projets  
- Documentation claire  
- Exemples complets  
- API stable et pérenne  

---

## 📌 État actuel
- Serveur **WebSocket (WSS)** fonctionnel  
- Client réseau en développement  
- Backend TCP/TLS en refonte  
- Réorganisation du dépôt en cours  
- API haut niveau en conception

---

## 🧰 Technologies
- Fortran 95+  
- C Wrappers  
- OpenSSL  
- `select()`  
- WebSocket RFC 6455  

---

## 📦 Dépendances
- GNU Fortran (recommandé)  
- Intel Fortran  
- LLVM Flang  

</details>

---

<details>
  <summary>🇬🇧 English Version</summary>

# GF‑Fortran‑SDK  
### A modern, modular, and extensible SDK for Fortran95

GF‑Fortran‑SDK aims to become a **complete ecosystem** for building modern applications in Fortran95.  
It goes far beyond “network tools”: the goal is to provide a **modular, clean, and extensible SDK** that gives Fortran developers everything they need to build networked, graphical, and interactive applications.

---

## 🧱 Modern Network Backend
- Independent modules: **TCP**, **TLS**, **WebSocket**  
- Minimal C wrappers to overcome F95 limitations  
- Clean, stable, maintainable architecture  
- Multi‑client handling via `select()`  
- WebSocket compliant with **RFC 6455**

---

## 🧩 Simple and intuitive high‑level API
Inspired by PureBasic, hiding all internal complexity:

```fortran
conn = OpenNetworkConnection("example.com", 443, useTLS = .true.)
call SendString(conn, "ping")
reply = ReceiveString(conn)
```

---

## 🎨 Future UI API (f90GL)
For building modern graphical interfaces:  
Windows, buttons, labels, sliders, automatic layout, network integration.

---

## 🌐 Future protocol support
- HTTP / HTTPS  
- MQTT  
- CoAP  
- POP3 / SMTP / IMAP  
- Redis  
- Memcached  
- Advanced WebSocket  
- Cloud services  

---

## 🛠️ Complete environment
- Specialized IDE  
- Project templates  
- Clear documentation  
- Full examples  
- Stable and long‑term API  

---

## 📌 Current status
- Functional **WebSocket (WSS)** server  
- Network client in development  
- TCP/TLS backend being redesigned  
- Repository cleanup in progress  
- High‑level API under design  

---

## 🧰 Technologies
- Fortran 95+  
- C Wrappers  
- OpenSSL  
- `select()`  
- WebSocket RFC 6455  

---

## 📦 Dependencies
- GNU Fortran (recommended)  
- Intel Fortran  
- LLVM Flang  

</details>


---

