
<p align="center">
  <img src="assets/gf-netstack.png" width="640">
</p>



## En cours de développement...  Currently in development...

---

<details>
  <summary>🇫🇷 Version Française</summary>

 
### SDK moderne, modulaire et extensible pour Fortran95 & Purebasic


## 🧱 Backend réseau moderne
- Modules indépendants : **TCP**, **TLS**, **WebSocket**  
- Wrappers C minimalistes pour contourner les limites du standard F95 & Purebasic 
- Architecture propre, stable et maintenable  
- Gestion multi‑clients via `select()`  
- WebSocket conforme **RFC 6455**


---

## 🧰 Command‑Line Interface (CLI)
J’ai écrit un petit script Lua pour simplifier les tâches courantes du SDK.
Il fonctionne de manière identique sur Windows, Linux et macOS.

### ▶️ Utilisation

Windows:

.\gf.ps1


Linux & macOS:

./gf.sh


### ▶️ Test rapide

```bash
./gf.sh hello
```
Résultat :  Hello from the unified GF CLI!

Ce test permet simplement de vérifier que tout fonctionne correctement.


### ⚙️ Commandes principales

* 🔍 Vérifier l’environnement

```bash
./gf.sh doctor
```

→ Vérifie les dépendances, l’environnement et l’état global du SDK.


* 🆕 Créer un nouveau module/projet

```bash
./gf.sh new @ARG
```

→ Crée un nouveau module ou projet nommé @ARG.


* 🏗️ Compiler un module

```bash
./gf.sh build @ARG
```

→ Compile @ARG.


* 🧹 Nettoyer les fichiers générés

```bash
./gf.sh clean @ARG
```

→ Supprime les fichiers générés pour @ARG.


* Démarrée l'apllication nommée @ARG...

```bash
./gf.sh run @ARG
```

→ Démarre l'application @ARG.

---



</details>

---

<details>
  <summary>🇬🇧 English Version</summary>

### SDK modern, modular and extensible for Fortran95 & Purebasic 


## 🧱 Modern Network Backend
- Independent modules: **TCP**, **TLS**, **WebSocket**  
- Minimal C wrappers to overcome F95 & Purebasic limitations  
- Clean, stable, maintainable architecture  
- Multi‑client handling via `select()`  
- WebSocket compliant with **RFC 6455**


---


## 🧰 Command‑Line Interface (CLI)
I wrote a small Lua script to simplify common SDK tasks.
It behaves the same on Windows, Linux, and macOS.

### ▶️ Usage

Windows:

```bash
.\gf.ps1
```

Linux & macOS:

```bash
./gf.sh
```


### ▶️ Quick Test

```bash
./gf.sh hello
```

Result:  Hello from the unified GF CLI!

This simple test ensures everything is working correctly.

### ⚙️ Main Commands

* 🔍 Check the environment

```bash
./gf.sh doctor
```

→ Checks dependencies, the environment, and the overall state of the SDK.


* 🆕 Create a new module/project

```bash
./gf.sh new @ARG
```

→ Creates a new module or project named @ARG.

* 🏗️ Build a module

```bash
./gf.sh build @ARG
```

→ Builds @ARG.

* 🧹 Clean generated files

```bash
./gf.sh clean @ARG
```

→ Removes generated files for @ARG.

* ▶️ Run the application named @ARG

```bash
./gf.sh run @ARG
```

→ Starts the application @ARG.

---


</details>


---

## 👤 Auteur  /  Author

* Guillaume Foisy  

* Passionné par la modernisation de l’écosystème Fortran95 & Purebasic

* Dedicated to modernizing the Fortran95 & Purebasic ecosystem
