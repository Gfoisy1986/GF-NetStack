# **fortran-net**  
### **Fortran + C Wrapper for TCP/TLS Networking**

`fortran-net` is a lightweight networking layer that bridges modern C networking (TCP/TLS) with clean Fortran interfaces.  
It provides a stable foundation for building secure agents, tunnels, and remote‑management tools — including the long‑term goal of powering encrypted GF‑Meca admin tunnels.

This project demonstrates how Fortran can interoperate with C and OpenSSL to create portable, high‑performance network clients and servers.

---

## 🚀 **Current Status (Working & Tested)**

### ✔ **C Wrappers**
- `tls_wrapper.c` and `tcp_wrapper.c` implemented
- Raw TCP sockets (listen, accept, connect)
- Basic send/recv over TCP
- OpenSSL initialization (TLS handshake coming next)

### ✔ **Fortran Module**
- `tls_module` with clean `_f` wrappers
- ISO_C_BINDING interfaces for all C functions
- Safe Fortran‑side wrappers for:
  - `tls_init_f`
  - `tls_listen_f`
  - `tls_accept_f`
  - `tls_connect_f`
  - `tls_send_f`
  - `tls_recv_f`
  - `tls_close_f`

### ✔ **Working Fortran Programs**
- `tls_server.f90` — listens, accepts, receives, responds  
- `tls_client.f90` — connects, sends, receives  
- Clean build with `make`

### ✔ **End‑to‑End Communication Works**
The client and server successfully exchange data over TCP using the Fortran ↔ C bridge.

---

## 🧱 **Architecture Overview**

```
Fortran Code
   │
   ▼
Fortran Module (ISO_C_BINDING)
   │
   ▼
C Wrapper (tcp/tls)
   │
   ▼
System Sockets + OpenSSL
```

This layered design keeps Fortran clean and modern while delegating low‑level networking to C.

---

## 🎯 **Project Vision**

The long‑term goal of `fortran-net` is to become the secure communication backbone for GF‑Meca’s remote administration ecosystem.

### The vision includes:

### 🔐 **1. Full TLS Encryption**
Replace raw TCP send/recv with:
- `SSL_accept`
- `SSL_connect`
- `SSL_read`
- `SSL_write`

### 🌐 **2. Secure GF‑Meca Agent Tunnel**
A lightweight Fortran agent running on client machines:

```
GF‑Meca Admin Panel  ⇄  TLS Tunnel  ⇄  Fortran Agent  ⇄ TCP/TLS ⇄ Local System Client
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

## 🛠️ **What’s Left To Do**

### 🔸 **1. Implement Real TLS Handshake**
- Add `SSL_CTX_new`, `SSL_new`, `SSL_set_fd`
- Add `SSL_connect` / `SSL_accept`
- Replace send/recv with SSL_read/SSL_write

### 🔸 **2. Certificate Loading**
- Load server certificate + key
- Optional client certificates
- Hostname verification

### 🔸 **3. Error Handling & Logging**
- Unified error codes
- Logging module
- Graceful reconnect logic

### 🔸 **4. JSON Protocol Layer**
- Define message types
- Implement encoder/decoder
- Add message framing

### 🔸 **5. Multi‑Client Support**
- Non‑blocking sockets
- Select/poll/epoll loop
- Threaded or event‑driven server

### 🔸 **6. Packaging**
- Build scripts
- Config files
- Deployment instructions

---

## 🧪 **Build & Run**

```bash
sudo make
./build/tls_server
./build/tls_client
```

---

## 🤝 **Contributions & Future Work**

This project is actively evolving.  
The next major milestone is **full TLS encryption**, unlocking secure GF‑Meca remote management.

If you want to extend, optimize, or integrate this into your own systems, contributions and ideas are welcome.

---

Guillaume Foisy
