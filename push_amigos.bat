@echo off
setlocal

REM Garante estado correto para Bolão com Amigos
git checkout ios\Runner.xcodeproj\project.pbxproj ios\Runner\GoogleService-Info.plist 2>nul

for /f "tokens=2 delims= " %%a in ('findstr "^version:" pubspec.yaml') do set FULLVER=%%a

git add .
git commit -m "release: Bolão com Amigos %FULLVER%"
git push origin main

echo.
echo Push para Bolão com Amigos (%FULLVER%) concluído.
