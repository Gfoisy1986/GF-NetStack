# GF‑Fortran‑SDK (Fortran95)

### En cours de développement...  Currently in development...

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

etc...
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
- OpenSSL
- f90gl

---

## 🧰 Outils inclus dans le SDK

### 🔵 Lua — Langage de script (MIT) Version 5.5.0
- Windows  i686 / x86_64 and ucrt64 / arm64
- Linux    ubuntu(x86_64)
- Léger, rapide, multiplateforme  
- Parfait pour automatiser les builds, générer du code et écrire des outils internes  
- Licence MIT très permissive  
- Intégration simple avec C et Fortran  

### 🟠 NASM — Assembleur x86/x64 (BSD 2‑clause)
- Assembleur moderne, stable et très utilisé  
- Idéal pour les routines bas niveau et l’optimisation  
- Licence BSD très permissive  
- Facile à redistribuer dans le SDK  

### 🟦 GCC — Compilateur C (GPL)
- Backend C utilisé pour les wrappers et les modules système  
- Très portable, fiable et mature  
- Redistribuable avec simple lien vers les sources GCC  

### 🟩 GFortran — Compilateur Fortran95 (GPL)
- Compilateur recommandé pour le SDK  
- Compatible Fortran95+  
- Redistribuable avec simple lien vers les sources GCC  
- Base principale pour compiler les modules du SDK  


---


## 👤 Auteur
Guillaume Foisy  
Créateur de GF‑Fortran‑SDK
Passionné par la modernisation de l’écosystème Fortran

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

etc...
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
- OpenSSL
- f90gl

---

## 🧰 Tools Included in the SDK  


### 🔵 Lua — Scripting Language (MIT License) Version 5.5.0
- Windows  i686 / x86_64 and ucrt64 / arm64
- Linux          ubuntu(x86_64)
- Lightweight, fast, and fully cross‑platform  
- Ideal for build automation, code generation, and internal tooling  
- MIT license (very permissive)  
- Easy to embed in C applications and integrate with GCC/gfortran  

### 🟠 NASM — x86/x64 Assembler (BSD 2‑Clause License)
- Modern, stable assembler for low‑level routines  
- Perfect for performance‑critical code and system‑level modules  
- BSD license (permissive and redistribution‑friendly)  
- Simple to package inside the SDK  

### 🟦 GCC — C Compiler (GPL License)
- Backend used for C wrappers and system modules  
- Mature, portable, and widely supported  
- Redistributable as long as a link to GCC source code is provided  
- Works seamlessly with NASM and Lua tooling  

### 🟩 GFortran — Fortran95 Compiler (GPL License)
- Recommended compiler for the SDK  
- Fully compatible with Fortran95+  
- Redistributable with a link to GCC sources  
- Core component for building the SDK’s Fortran modules  


---


## 👤 Author
Guillaume Foisy  
Creator of GF‑Fortran‑SDK
Dedicated to modernizing the Fortran ecosystem

</details>


---

