fortran-net
Fortran + C Wrapper for TCP/TLS Networking
 is a lightweight networking layer that bridges modern C networking (TCP/TLS) with clean Fortran interfaces.
It provides a stable foundation for building secure agents, tunnels, and remote‑management tools — including the long‑term goal of powering encrypted GF‑Meca admin tunnels.
This project demonstrates how Fortran can interoperate with C and OpenSSL to create portable, high‑performance network clients and servers.

🔐 Generating TLS Certificates
To keep the repository secure, TLS keys and certificates are not included.
You must generate your own  and  before running the TLS server.
Both Ubuntu and Windows PowerShell use the same OpenSSL command.

🔐 1. Generate TLS cert + key on Ubuntu (Linux)
Open a terminal and run:

This creates:
• 	server.key → private key
• 	server.pem → certificate
Place both files in the same directory where you run your TLS server.

🔐 2. Generate TLS cert + key in PowerShell (Windows)
PowerShell uses the same OpenSSL command (Git for Windows includes OpenSSL).
Run this in PowerShell:


🚀 Current Status (Working & Tested)
✔ C Wrappers
• 	 and  implemented
• 	Raw TCP sockets (listen, accept, connect)
• 	TLS handshake with OpenSSL
• 	Per‑socket SSL objects (multi‑client safe)
• 	Encrypted send/recv using  / 
✔ Fortran Module
• 	 with clean ISO_C_BINDING interfaces
• 	Safe Fortran wrappers for:
• 	
• 	
• 	
• 	
• 	
• 	
• 	
• 	
✔ Working Fortran Programs
• 	 — multi‑session JSON server
• 	 — persistent JSON client
• 	Clean build with 
✔ End‑to‑End TLS Communication Works
The client and server exchange JSON messages over encrypted TLS using the Fortran ↔ C ↔ OpenSSL bridge.

🧱 Architecture Overview

This layered design keeps Fortran clean and modern while delegating low‑level networking to C.

🎯 Project Vision
The long‑term goal of  is to become the secure communication backbone for GF‑Meca’s remote administration ecosystem.
🔐 1. Full TLS Encryption
• 	
• 	
• 	
• 	
🌐 2. Secure GF‑Meca Agent Tunnel

📦 3. JSON‑over‑TLS Protocol
Structured messages for:
• 	authentication
• 	system metrics
• 	file operations
• 	service control
• 	logs
• 	remote execution
📱 4. Mobile‑Friendly Admin Access
Android tablet → GF‑Meca → TLS tunnel → remote agent.
🧩 5. Multi‑Client Server
A Fortran server capable of handling multiple agents simultaneously.

🛠️ What’s Left To Do
🔸 1. Certificate Verification
• 	Optional client certificates
• 	Hostname verification
🔸 2. Error Handling & Logging
• 	Unified error codes
• 	Logging module
• 	Graceful reconnect logic
🔸 3. JSON Protocol Layer
• 	Message framing
• 	Command routing
• 	Authentication handshake
🔸 4. Multi‑Client Enhancements
• 	Non‑blocking sockets
• 	Select/poll/epoll loop
• 	Threaded or event‑driven server
🔸 5. Packaging
• 	Build scripts
• 	Config files
• 	Deployment instructions

🧪 Build & Run


🤝 Contributions & Future Work
This project is actively evolving.
The next major milestone is expanding the JSON protocol and integrating it into GF‑Meca’s remote management system.
Ideas, improvements, and contributions are welcome.

Guillaume Foisy
