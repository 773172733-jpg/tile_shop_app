@echo off
echo Stopping existing Flutter processes...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :8000') do (
    echo Killing PID %%a
    taskkill /F /PID %%a 2>nul
)
timeout /t 2 /nobreak >nul
echo Starting Flutter Web...
cd /d "%~dp0"
D:\flutter\bin\flutter.bat run -d web-server --web-port=8000
echo.
echo Server started at http://localhost:8000
echo Opening browser...
start http://localhost:8000
