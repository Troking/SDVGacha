@echo off
cd /d "%~dp0"
echo Opening Godot Editor...
start "" "%~dp0tools\Godot_v4.7.2-stable_win64.exe" -e --path "%~dp0game"
