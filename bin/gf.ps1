$ErrorActionPreference = "SilentlyContinue"

# Detect gfortran
if (-not (Get-Command gfortran)) {
    Write-Host "[GF] gfortran not found in PATH."
    Write-Host "Install a system-wide compiler or adjust your PATH."
    exit 1
}

# Detect lua (optional)
if (-not (Get-Command lua)) {
    Write-Host "[GF] lua not found in PATH. Lua features will be disabled."
}

# Set SDK root
$GF_SDK_ROOT = Split-Path $PSScriptRoot -Parent

# Run GF CLI
lua "$GF_SDK_ROOT/tools/gf.lua" @args
