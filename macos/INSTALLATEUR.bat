@echo off
chcp 65001 >nul
cd /d "%~dp0"
where pythonw >nul 2>nul
if errorlevel 1 (
    echo Python n'est pas installe.
    echo.
    set /p REP="Veux-tu que je l'installe automatiquement (winget) ? [O/N] "
    setlocal enabledelayedexpansion
    if /i "!REP!"=="O" (
        winget install -e --id Python.Python.3.12 --accept-package-agreements --accept-source-agreements
        echo.
        echo Python installe. FERME cette fenetre et relance INSTALLATEUR.bat.
    ) else (
        start https://www.python.org/downloads/
        echo Installe Python en cochant "Add Python to PATH", puis relance INSTALLATEUR.bat.
    )
    pause
    exit /b 1
)
start "" pythonw "%~dp0installateur.pyw"
