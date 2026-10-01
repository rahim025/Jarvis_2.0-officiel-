@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo Creation de JARVIS_Installateur.exe (necessite Python)...
python -m pip install pyinstaller
python -m PyInstaller --noconsole --onefile --name JARVIS_Installateur --icon assets\jarvis.ico installateur.pyw
copy /Y dist\JARVIS_Installateur.exe JARVIS_Installateur.exe >nul
echo.
echo Termine : JARVIS_Installateur.exe est dans ce dossier.
pause
