@echo off
echo.
echo ============================================
echo   Generating server.key and server.pem
echo   Self-signed certificate, RSA 2048 bits
echo ============================================
echo.

REM Run OpenSSL to generate key + certificate
openssl req -x509 -newkey rsa:2048 -keyout server.key -out server.pem -days 365 -nodes

echo.
echo ============================================
echo   Certificate generation complete
echo   - Private key: server.key
echo   - Certificate: server.pem
echo ============================================
echo.
pause
