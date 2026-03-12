# **fortran-net**  
### **Fortran + C Wrapper for TCP/TLS Networking**

`fortran-net` is a lightweight networking layer that bridges modern C networking (TCP/TLS) with clean Fortran interfaces.  
It provides a stable foundation for building secure agents, tunnels, and remote‑management tools — including the long‑term goal of powering encrypted GF‑Meca admin tunnels.

This project demonstrates how Fortran can interoperate with C and OpenSSL to create portable, high‑performance network clients and servers.

---

# 🔐 **Generating TLS Certificates**

To keep the repository secure, **TLS keys and certificates are not included**.  
You must generate your own `server.pem` and `server.key` before running the TLS server.

Both Ubuntu and Windows PowerShell use the same OpenSSL command.

---

## 🔐 **1. Generate TLS cert + key on Ubuntu (Linux)**

Open a terminal and run:

```bash
openssl req -x509 -newkey rsa:2048 \
  -keyout server.key \
  -out server.pem \
  -days 365 \
  -nodes \
  -subj "/CN=localhost"
```

This creates:

- **server.key** → private key  
- **server.pem** → certificate  

Place both files in the same directory where you run your TLS server.

---

## 🔐 **2. Generate TLS cert + key in PowerShell (Windows)**

PowerShell uses the same OpenSSL command (Git for Windows includes OpenSSL).

Run this in PowerShell:

```powershell
openssl req -x509 -newkey rsa:2048 `
  -keyout server.key `
  -out server.pem `
  -days 365 `
  -nodes `
  -subj "/CN=localhost"
```

---

# 🚀 **Current Status (Working & Tested)**

### ✔ **C Wrappers**
- `tls_wrapper.c` and `tcp_wrapper.c` implemented  
- Raw TCP sockets (listen, accept, connect)  
- TLS handshake with OpenSSL  
- Per‑socket SSL objects (multi‑client safe)  
- Encrypted send/recv using `SSL_read` / `SSL_write`  

### ✔ **Fortran Module**
- `tls_module` with clean ISO_C_BINDING interfaces  
- Safe Fortran wrappers for:
  - `tls_init_server_f`
  - `tls_init_client_f`
  - `tls_listen_f`
  - `tls_accept_f`
  - `tls_connect_f`
  - `tls_send_f`
  - `tls_recv_f`
  - `tls_close_f`

### ✔ **Working Fortran Programs**
- `tls_server.f90` — multi‑session JSON server  
- `tls_client.f90` — persistent JSON client  
- Clean build with `make`

### ✔ **End‑to‑End TLS Communication Works**
The client and server exchange JSON messages over encrypted TLS using the Fortran ↔ C ↔ OpenSSL bridge.

---

# 🧱 **Architecture Overview**

```
Fortran Code
   │
   ▼
Fortran Module (ISO_C_BINDING)
   │
   ▼
C Wrapper (TCP/TLS)
   │
   ▼
System Sockets + OpenSSL
```

This layered design keeps Fortran clean and modern while delegating low‑level networking to C.

---

# 🎯 **Project Vision**

The long‑term goal of `fortran-net` is to become the secure communication backbone for GF‑Meca’s remote administration ecosystem.

### 🔐 **1. Full TLS Encryption**
- `SSL_accept`
- `SSL_connect`
- `SSL_read`
- `SSL_write`

### 🌐 **2. Secure GF‑Meca Agent Tunnel**

```
GF‑Meca Admin Panel ⇄ TLS Tunnel ⇄ Fortran Agent ⇄ Local System Client
```

### 📦 **3. JSON‑over‑TLS Protocol**
Structured messages for:
- authentication  
- system metrics  
- file operations  
- service control  
- logs  
- remote execution  

### 📱 **4. Mobile‑Friendly Admin Access**
Android tablet → GF‑Meca → TLS tunnel → remote agent.

### 🧩 **5. Multi‑Client Server**
A Fortran server capable of handling multiple agents simultaneously.

---

# 🛠️ **What’s Left To Do**

### 🔸 **1. Certificate Verification**
- Optional client certificates  
- Hostname verification  

### 🔸 **2. Error Handling & Logging**
- Unified error codes  
- Logging module  
- Graceful reconnect logic  

### 🔸 **3. JSON Protocol Layer**
- Message framing  
- Command routing  
- Authentication handshake  

### 🔸 **4. Multi‑Client Enhancements**
- Non‑blocking sockets  
- Select/poll/epoll loop  
- Threaded or event‑driven server  

### 🔸 **5. Packaging**
- Build scripts  
- Config files  
- Deployment instructions  

---

# 🐧 **Ubuntu — Installation complète**

### ✅ **1. Mettre à jour le système**
```bash
sudo apt update && sudo apt upgrade -y
```

### ✅ **2. Installer gcc, gfortran et binutils**
```bash
sudo apt install -y gcc gfortran binutils make
```

### 📦 Ce que ça installe réellement
| Paquet | Rôle |
|--------|------|
| **gcc** | Compilateur C (nécessaire pour beaucoup de libs) |
| **gfortran** | Compilateur Fortran 95/2003/2008 |
| **binutils** | `ld`, `as`, `objdump`, `ar`, etc. |
| **make** | (optionnel mais indispensable pour les builds) |

### 🔍 Vérification
```bash
gcc --version
gfortran --version
ld --version
```

---

# 🪟 **Windows (PowerShell) — Installation via MSYS2 (recommandé)**

MSYS2 est la méthode la plus propre pour avoir un environnement GNU complet sous Windows.

### ✅ **1. Installer MSYS2**
Télécharge MSYS2 depuis :  
https://www.msys2.org/

Puis ouvre **MSYS2 MSYS** et mets à jour :
```bash
pacman -Syu
```
Redémarre MSYS2 si demandé, puis :
```bash
pacman -Syu
```

### ✅ **2. Installer gcc, gfortran et binutils**
Dans **MSYS2 MinGW64** :
```bash
pacman -S mingw-w64-x86_64-gcc mingw-w64-x86_64-gcc-fortran mingw-w64-x86_64-binutils
```

### 🔍 Vérification
Toujours dans MinGW64 :
```bash
gcc --version
gfortran --version
ld --version
```

---

# 🪟 **Windows (PowerShell) — Installation via WSL (alternative simple)**

Si tu préfères compiler dans un vrai Linux sous Windows :

### 1. Activer WSL
PowerShell admin :
```powershell
wsl --install
```

### 2. Installer Ubuntu
Puis dans Ubuntu :
```bash
sudo apt update
sudo apt install gcc gfortran binutils make
```

# 🐧 **Ubuntu — Installation OpenSSL (librairies + headers)**

### ✅ Installer OpenSSL + les headers de développement
Pour compiler ton code Fortran/C avec TLS, il te faut **libssl-dev** :

```bash
sudo apt update
sudo apt install -y openssl libssl-dev
```

### 📦 Ce que ça installe réellement
| Paquet | Rôle |
|--------|------|
| **openssl** | Outil CLI (`openssl s_client`, `openssl genrsa`, etc.) |
| **libssl-dev** | Headers C (`openssl/ssl.h`) + librairies `libssl.so` et `libcrypto.so` |

### 🔍 Vérification
```bash
openssl version
```

---

# 🪟 **Windows — Installation OpenSSL (PowerShell)**

Sous Windows, il n’y a pas de paquet officiel Microsoft.  
La méthode la plus propre pour un environnement de build GNU (gcc/gfortran) est **MSYS2**.

---

## ✔ **Méthode recommandée : MSYS2**

### 1. Installer MSYS2  
[https://www.msys2.org/](https://www.msys2.org/)

### 2. Ouvrir **MSYS2 MinGW64** et installer OpenSSL
```bash
pacman -S mingw-w64-x86_64-openssl
```

### 📦 Ce que ça installe
- `libssl-3.dll`
- `libcrypto-3.dll`
- Headers : `openssl/*.h`
- Librairies : `libssl.a`, `libcrypto.a`

### 🔍 Vérification
```bash
openssl version
```

---

## ✔ **Alternative : OpenSSL officiel (Win64)**

Si tu veux OpenSSL **sans MSYS2**, tu peux installer la version Win64 maintenue par Shining Light Productions.

### 1. Télécharger  
`https://slproweb.com/products/Win32OpenSSL.html` [(slproweb.com in Bing)](https://www.bing.com/search?q="https%3A%2F%2Fslproweb.com%2Fproducts%2FWin32OpenSSL.html")

Choisir :  
**Win64 OpenSSL v3.x.x (Light)**

### 2. Ajouter au PATH (PowerShell admin)
```powershell
setx PATH "$env:PATH;C:\Program Files\OpenSSL-Win64\bin"
```

### 3. Vérifier
```powershell
openssl version
```

---

# 🧠 Notes importantes pour ton workflow Fortran/C

### ✔ **Linker (Ubuntu)**
Pour gfortran :
```bash
gfortran main.f90 -lssl -lcrypto -o app
```

### ✔ **Linker (Windows MSYS2 MinGW64)**
```bash
gfortran main.f90 -lssl -lcrypto -o app.exe
```

### ✔ **DLL runtime (Windows)**
Ton EXE aura besoin de :
- `libssl-3.dll`
- `libcrypto-3.dll`

Tu peux les mettre :
- dans le même dossier que ton EXE  
ou  
- dans un dossier du PATH


# 🧪 **Build & Run**

```bash
sudo make
./build/tls_server
./build/tls_client
```

---

# 🤝 **Contributions & Future Work**

This project is actively evolving.  
The next major milestone is expanding the JSON protocol and integrating it into GF‑Meca’s remote management system.

Ideas, improvements, and contributions are welcome.

---

Guillaume Foisy


