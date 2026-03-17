#!/bin/sh

# Detect gfortran
if ! command -v gfortran >/dev/null 2>&1; then
    echo "[GF] gfortran not found in PATH."
    echo "Install a system-wide compiler or adjust your PATH."
    exit 1
fi

# Detect lua (optional)
if ! command -v lua >/dev/null 2>&1; then
    echo "[GF] lua not found in PATH. Lua features will be disabled."
fi

# Set SDK root
GF_SDK_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Run GF CLI
lua "$GF_SDK_ROOT/scripts/gf.lua" "$@"
