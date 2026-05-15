@echo off
setlocal

REM 1. Substitui Bundle ID no project.pbxproj (apenas PRODUCT_BUNDLE_IDENTIFIER = com.salles.bolao;)
powershell -Command "(Get-Content 'ios\Runner.xcodeproj\project.pbxproj') -replace 'PRODUCT_BUNDLE_IDENTIFIER = com\.salles\.bolao;', 'PRODUCT_BUNDLE_IDENTIFIER = com.salles.bolaocopadomundo;' | Set-Content 'ios\Runner.xcodeproj\project.pbxproj'"

REM 2. Copia o plist do Colegas
copy /y "ios\Runner\GoogleService-Info_colegas.plist" "ios\Runner\GoogleService-Info.plist" >nul

for /f "tokens=2 delims= " %%a in ('findstr "^version:" pubspec.yaml') do set FULLVER=%%a

REM 3. Commit e push para colegas
git add .
git commit -m "release: Bolão com Colegas %FULLVER%"
git push colegas main

REM 4. Reverte alterações locais
git checkout ios\Runner.xcodeproj\project.pbxproj ios\Runner\GoogleService-Info.plist

echo.
echo Push para Bolão com Colegas (%FULLVER%) concluído. Estado local restaurado.
