@echo off
title DevCodeForge
cls

:menu
echo.
echo  ============================================================
echo   [*] DevCodeForge - IP Tool
echo   [*] Version 0.0.2
echo   [1] IP-Adresse orten       (IP eingeben - Standort)
echo   [2] IP-Adresse finden      (Standort eingeben - IPs)
echo   [/hilfe] Hilfe
echo   [0] Beenden
echo  ------------------------------------------------------------
echo.
set /p choice=" Auswahl: "

if /i "%choice%"=="/hilfe" goto hilfe
if "%choice%"=="1"         goto ip_orten
if "%choice%"=="2"         goto standort_zu_ip
if "%choice%"=="0"         goto exit

echo.
echo  [!] Ungueltige Eingabe.
pause
cls
goto menu

:: ============================================================
::  HILFE
:: ============================================================
:hilfe
cls
echo.
echo  ============================================================
echo   DevCodeForge - Hilfe
echo  ============================================================
echo.
echo   [1] IP-Adresse orten
echo   ------------------------------------------------------
echo   Gibt den genauen Standort einer IP-Adresse aus.
echo   Beispiele: 8.8.8.8 / 1.1.1.1
echo   Leer lassen = eigene IP wird geortet.
echo   Zeigt: Land, Region, Stadt, ISP, Koordinaten usw.
echo.
echo   [2] IP-Adresse finden
echo   ------------------------------------------------------
echo   Sucht registrierte IP-Ranges fuer einen Standort.
echo   Beispiele: Berlin / Japan / New York / France
echo   Zeigt bis zu 15 IP-Netzwerkbloecke der Region.
echo.
echo   [0] Beenden
echo   ------------------------------------------------------
echo   Schliesst DevCodeForge.
echo.
echo   HINWEIS: Internetverbindung fuer Option 1 und 2 noetig.
echo  ============================================================
echo.
pause
cls
goto menu

:: ============================================================
::  IP ORTEN
:: ============================================================
:ip_orten
cls
echo.
echo  ============================================================
echo   [1] IP-Adresse orten
echo  ============================================================
echo.
set /p zielip=" IP-Adresse eingeben (leer = eigene IP): "

if "%zielip%"=="" (
    set "apiurl=http://ip-api.com/json/"
) else (
    set "apiurl=http://ip-api.com/json/%zielip%"
)

echo.
echo  [>>] Abfrage laeuft...
echo.

powershell -NoProfile -Command ^
  "try { $r = Invoke-RestMethod -Uri '%apiurl%' -UseBasicParsing; " ^
  "if ($r.status -eq 'success') { " ^
  "  Write-Host '  ----------------------------------------'; " ^
  "  Write-Host '  IP-Adresse   : ' $r.query; " ^
  "  Write-Host '  Land         : ' $r.country '(' $r.countryCode ')'; " ^
  "  Write-Host '  Region       : ' $r.regionName; " ^
  "  Write-Host '  Stadt        : ' $r.city; " ^
  "  Write-Host '  PLZ          : ' $r.zip; " ^
  "  Write-Host '  ISP          : ' $r.isp; " ^
  "  Write-Host '  Organisation : ' $r.org; " ^
  "  Write-Host '  Koordinaten  : ' $r.lat ',' $r.lon; " ^
  "  Write-Host '  Zeitzone     : ' $r.timezone; " ^
  "  Write-Host '  ----------------------------------------'; " ^
  "} else { Write-Host '  [FEHLER]: ' $r.message } " ^
  "} catch { Write-Host '  [FEHLER] Keine Verbindung oder ungueltige IP.' }"

echo.
pause
cls
goto menu

:: ============================================================
::  STANDORT -> IP FINDEN
:: ============================================================
:standort_zu_ip
cls
echo.
echo  ============================================================
echo   [2] IP-Adressen nach Standort finden
echo  ============================================================
echo.
set /p standort=" Standort eingeben (Stadt oder Land): "
echo.
echo  [>>] Suche laeuft, bitte warten...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$standort = '%standort%';" ^
  "$headers = @{ 'User-Agent' = 'DevCodeForge/1.0' };" ^
  "try {" ^
  "  $geoUrl = 'https://nominatim.openstreetmap.org/search?q=' + [Uri]::EscapeDataString($standort) + '&format=json&addressdetails=1&limit=1';" ^
  "  $geo = Invoke-RestMethod -Uri $geoUrl -Headers $headers -UseBasicParsing;" ^
  "  if (-not $geo -or $geo.Count -eq 0) { Write-Host '  [FEHLER] Standort nicht gefunden.'; exit };" ^
  "  $place = $geo[0];" ^
  "  $cc = $place.address.country_code.ToUpper();" ^
  "  $displayName = ($place.display_name -split ',')[0..2] -join ',';" ^
  "  Write-Host '  Standort    :' $displayName;" ^
  "  Write-Host '  Laendercode :' $cc;" ^
  "  Write-Host '';" ^
  "  $ripeUrl = 'https://stat.ripe.net/data/country-resource-list/data.json?resource=' + $cc;" ^
  "  $ripe = Invoke-RestMethod -Uri $ripeUrl -UseBasicParsing;" ^
  "  $ranges = $ripe.data.resources.ipv4 | Select-Object -First 15;" ^
  "  if ($ranges -and $ranges.Count -gt 0) {" ^
  "    Write-Host '  Registrierte IP-Ranges (erste 15):';" ^
  "    Write-Host '  ----------------------------------------';" ^
  "    foreach ($r in $ranges) { Write-Host '   ' $r };" ^
  "    Write-Host '  ----------------------------------------';" ^
  "    Write-Host '  Tipp: Diese Ranges gehoeren Providern in der Region.';" ^
  "  } else { Write-Host '  [INFO] Keine IP-Ranges fuer diesen Standort gefunden.' };" ^
  "} catch { Write-Host '  [FEHLER] ' $_.Exception.Message }"

echo.
pause
cls
goto menu

:: ============================================================
::  BEENDEN
:: ============================================================
:exit
cls
echo.
echo  Auf Wiedersehen!
echo.
timeout /t 2 >nul
exit
