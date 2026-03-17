@echo off
setlocal

:: Detect gfortran
where gfortran >nul 2>nul
if errorlevel 1 (
    echo [GF] gfortran not found in PATH.
    echo Install a system-wide compiler or adjust your PATH.
    exit /b 1
)

:: Detect lua (optional)
where lua >nul 2>nul
if errorlevel 1 (
    echo [GF] lua not found in PATH. Lua features will be disabled.
)

:: Set SDK root
set GF_SDK_ROOT=%~dp0..

:: Run GF CLI
lua "%GF_SDK_ROOT%\scripts\gf.lua" %*
