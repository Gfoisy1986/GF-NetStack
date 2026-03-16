# GF‑Fortran‑SDK (Fortran95)

### En cours de développement...  Currently in development...

---

<details>
  <summary>🇫🇷 Version Française</summary>

 
## SDK moderne, modulaire et extensible pour Fortran95


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



</details>

---

<details>
  <summary>🇬🇧 English Version</summary>

# GF‑Fortran‑SDK  


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


</details>


---

## 👤 Auteur  /  Author

* Guillaume Foisy  

* Passionné par la modernisation de l’écosystème Fortran

* Dedicated to modernizing the Fortran ecosystem
