@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo 正在启动 Flutter 到 Chrome...
D:\flutter\bin\flutter run -d chrome --web-port=8000
pause
