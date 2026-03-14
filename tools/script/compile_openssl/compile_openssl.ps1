# ================================
# Build OpenSSL 3.5.x for Windows
# ================================

$VERSION = "3.5.5"
$ARCHIVE = "openssl-$VERSION.tar.gz"
$URL = "https://www.openssl.org/source/$ARCHIVE"

# Create deps folder
New-Item -ItemType Directory -Force -Path "deps\openssl\windows" | Out-Null

# Download source
Invoke-WebRequest -Uri $URL -OutFile $ARCHIVE

# Extract
tar -xvf $ARCHIVE
Set-Location "openssl-$VERSION"

# Configure for 64-bit Windows
perl Configure VC-WIN64A --prefix="$PWD\install"

# Build
nmake
nmake install

# Copy to SDK deps folder
Copy-Item -Recurse "install\*" "..\deps\openssl\windows"

Write-Host "OpenSSL $VERSION built successfully for Windows!"
