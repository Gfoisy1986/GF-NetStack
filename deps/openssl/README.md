# OpenSSL Dependency (GF‑Fortran‑SDK)

This directory contains the **precompiled OpenSSL binaries** used by the  
**GF‑Fortran‑SDK** for TLS, cryptography, certificate handling, and secure  
network communication.

OpenSSL is an external dependency and **is not developed by the GF‑Fortran‑SDK**.  
It is redistributed here to provide a fully self‑contained SDK with no external  
installation required.

---

## 📦 Included Versions

This folder currently includes:

- **OpenSSL 3.5.5 (LTS – supported until 2030)**  
- Precompiled binaries for:
  - Windows (x64)
  - Linux (x64)
  - macOS (Intel/ARM) *(if applicable)*

Each platform folder contains:

```
bin/      → runtime DLL/so/dylib
lib/      → static and import libraries
include/  → OpenSSL public headers
```

---

## 🔧 Why OpenSSL is Included

The GF‑Fortran‑SDK uses OpenSSL for:

- TLS client/server support  
- Cryptographic primitives (SHA, AES, RSA, etc.)  
- Certificate parsing and validation  
- Secure sockets and encrypted channels  

Bundling OpenSSL ensures:

- consistent behavior across platforms  
- no external installation required  
- reproducible builds  
- simplified onboarding for SDK users

---

## 📜 Licensing

OpenSSL is licensed under the **Apache License 2.0**, with the  
**OpenSSL License Exception**.

The full license text is included in:

```
deps/openssl/LICENSE.txt
```

You must comply with the OpenSSL license if you redistribute the SDK or build  
derivative works that include these binaries.

For more information, visit the official OpenSSL website:

https://www.openssl.org/

---

## 📁 Directory Structure

```
deps/
 └── openssl/
      ├── windows/
      │    ├── bin/
      │    ├── lib/
      │    └── include/
      ├── linux/
      │    ├── bin/
      │    ├── lib/
      │    └── include/
      └── macos/   (optional)
           ├── bin/
           ├── lib/
           └── include/
```

---

## 🛠️ Build Scripts

The SDK includes helper scripts to rebuild OpenSSL from source:

- `build_openssl_windows.ps1`
- `build_openssl_linux.sh`

These scripts download, configure, compile, and install OpenSSL into the  
appropriate `deps/openssl/<platform>/` directory.

---

## 🤝 Credits

OpenSSL is an open‑source project maintained by the OpenSSL Software Foundation.  
We thank the contributors for their work and commitment to secure communication.

GF‑Fortran‑SDK only redistributes the official binaries and does not modify the  
OpenSSL source code.
```

---
