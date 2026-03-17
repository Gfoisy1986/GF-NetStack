#!/usr/bin/env bash

# ============================================================
#  generate-cert.sh
#  Creates a self‑signed certificate: server.key + server.pem
#  Valid for 365 days, RSA 2048 bits, no password on key.
# ============================================================

set -e

echo "🔐 Generating server.key and server.pem..."

openssl req \
  -x509 \
  -newkey rsa:2048 \
  -keyout server.key \
  -out server.pem \
  -days 365 \
  -nodes

echo "✅ Certificate generation complete."
echo "   - Private key: server.key"
echo "   - Certificate: server.pem"
