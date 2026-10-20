@echo off
cd /d "%~dp0"
echo Starting SDVGacha...
start "" "%~dp0tools\Godot_v4.7.2-stable_win64.exe" --path "%~dp0game"
