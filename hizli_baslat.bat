@echo off
title Kolay Iletisim (SpeakBridge) - Hizli Baslat
echo ==============================================
echo   Kolay Iletisim Yerel Sunucusu Baslatiliyor
echo   Adres: http://localhost:8088
echo ==============================================
cd /d "%~dp0"
start http://localhost:8088
python -m http.server 8088 --directory build\web
pause
