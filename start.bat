@echo off
chcp 65001 >nul
echo.
echo ========================================
echo    启动瓷砖店铺 APP - Flutter Web
echo ========================================
echo.

REM 查找并杀掉占用 8000 端口的进程
echo [1/3] 检查端口 8000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":8000 " ^| findstr "LISTENING"') do (
    echo       发现占用进程 PID: %%a，正在关闭...
    taskkill /F /PID %%a >nul 2>&1
    timeout /t 1 /nobreak >nul
)

echo [2/3] 启动 Flutter Web 服务器...
cd /d "%~dp0"
start "" /B cmd /c "D:\flutter\bin\flutter.bat run -d web-server --web-port=8000 --no-hot"

echo [3/3] 等待服务器启动...
timeout /t 8 /nobreak >nul

echo.
echo ========================================
echo    服务器已启动！
echo    访问地址：http://localhost:8000
echo ========================================
echo.

REM 自动打开浏览器
start http://localhost:8000

echo.
echo 按任意键退出此窗口...
pause >nul
