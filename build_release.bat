@echo off
chcp 65001 >nul
echo.
echo ========================================
echo    构建 Flutter Web 发布版本
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] 清理旧的构建...
call D:\flutter\bin\flutter clean

echo.
echo [2/2] 构建发布版本...
call D:\flutter\bin\flutter build web --release

echo.
echo ========================================
echo    构建完成！
echo ========================================
echo.

pause
