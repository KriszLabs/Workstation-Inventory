@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

title Workstation Inventory v1.1
color 0A
cls

echo.
echo ========================================
echo      WORKSTATION INVENTORY v1.1
echo ========================================
echo.
echo Adatok lekérdezése, kérlek várj..

rem ================== POWERSHELL PARANCS ÖSSZEÁLLÍTÁSA ==================
rem Minden sor KULCS=ÉRTÉK formátumban jön vissza, így az üres értékek
rem nem tolják el a sorrendet (üres érték helyett "N/A" jön).
set "PS=$ErrorActionPreference='SilentlyContinue';"
set "PS=%PS%function o($k,$v){if(-not $v){$v='N/A'};'INV_'+$k+'='+$v};"
set "PS=%PS%$cs=Get-CimInstance Win32_ComputerSystem;"
set "PS=%PS%$bios=Get-CimInstance Win32_BIOS;"
set "PS=%PS%$os=Get-CimInstance Win32_OperatingSystem;"
set "PS=%PS%$cpu=@(Get-CimInstance Win32_Processor)[0];"
set "PS=%PS%$n=@(Get-NetIPConfiguration | Where-Object {$_.IPv4DefaultGateway})[0];"
set "PS=%PS%o 'MANUFACTURER' $cs.Manufacturer;"
set "PS=%PS%o 'MODEL' $cs.Model;"
set "PS=%PS%o 'SERIAL' $bios.SerialNumber;"
set "PS=%PS%o 'BIOS' ($bios.SMBIOSBIOSVersion);"
set "PS=%PS%o 'BIOSDATE' ($bios.ReleaseDate.ToString('yyyy-MM-dd'));"
set "PS=%PS%o 'OSNAME' $os.Caption;"
set "PS=%PS%o 'OSVER' ($os.Version+' (build '+$os.BuildNumber+')');"
set "PS=%PS%o 'ARCH' $os.OSArchitecture;"
set "PS=%PS%o 'INSTALLED' ($os.InstallDate.ToString('yyyy-MM-dd'));"
set "PS=%PS%o 'BOOT' ($os.LastBootUpTime.ToString('yyyy-MM-dd HH:mm'));"
set "PS=%PS%o 'UPTIMEH' ([int]((Get-Date)-$os.LastBootUpTime).TotalHours);"
set "PS=%PS%o 'DOMAIN' $cs.Domain;"
set "PS=%PS%o 'CPU' $cpu.Name;"
set "PS=%PS%o 'CORES' $cpu.NumberOfCores;"
set "PS=%PS%o 'THREADS' $cpu.NumberOfLogicalProcessors;"
set "PS=%PS%o 'RAMGB' ([math]::Round($cs.TotalPhysicalMemory/1GB,0));"
set "PS=%PS%o 'GPU' ((Get-CimInstance Win32_VideoController | ForEach-Object {$_.Name}) -join ' / ');"
set "PS=%PS%o 'DISKS' ((Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' | ForEach-Object {$_.DeviceID+' '+[math]::Round($_.FreeSpace/1GB)+'/'+[math]::Round($_.Size/1GB)+' GB'}) -join '; ');"
set "PS=%PS%o 'NETADAPTER' $n.InterfaceAlias;"
set "PS=%PS%o 'IP' ($n.IPv4Address.IPAddress -join ', ');"
set "PS=%PS%o 'MAC' ((Get-NetAdapter -Name $n.InterfaceAlias).MacAddress);"
set "PS=%PS%o 'GW' ($n.IPv4DefaultGateway.NextHop -join ', ');"
set "PS=%PS%o 'DNS' ($n.DNSServer.ServerAddresses -join ', ');"

rem ================== LEKÉRDEZÉS ÉS VÁLTOZÓK FELTÖLTÉSE ==================
for /f "usebackq tokens=1,* delims==" %%A in (`powershell -NoProfile -Command "%PS%"`) do (
    set "%%A=%%B"
)

rem Alapérték, ha a PowerShell egyáltalán nem futott le
for %%V in (MANUFACTURER MODEL SERIAL BIOS BIOSDATE OSNAME OSVER ARCH INSTALLED BOOT UPTIMEH DOMAIN CPU CORES THREADS RAMGB GPU DISKS NETADAPTER IP MAC GW DNS) do (
    if not defined INV_%%V set "INV_%%V=Ismeretlen"
)

rem ================== KIÍRÁS ==================
cls
echo.
echo ========================================
echo      WORKSTATION INVENTORY v1.1
echo ========================================
echo Futtatás ideje: %date% %time%
echo.
echo [ALAPINFORMÁCIÓK]
echo   Gépnév:               %COMPUTERNAME%
echo   Felhasználó:          %USERDOMAIN%\%USERNAME%
echo   Domain/Munkacsoport:  !INV_DOMAIN!
echo.
echo [HARDVER]
echo   Gyártó:               !INV_MANUFACTURER!
echo   Modell:               !INV_MODEL!
echo   Sorozatszám:          !INV_SERIAL!
echo   BIOS verzió:          !INV_BIOS! (!INV_BIOSDATE!)
echo   Processzor:           !INV_CPU!
echo   Magok / szálak:       !INV_CORES! / !INV_THREADS!
echo   Memória:              !INV_RAMGB! GB
echo   Videókártya:          !INV_GPU!
echo   Lemezek (szabad/össz): !INV_DISKS!
echo.
echo [OPERÁCIÓS RENDSZER]
echo   Rendszer:             !INV_OSNAME!
echo   Verzió:               !INV_OSVER!
echo   Architektúra:         !INV_ARCH!
echo   Telepítés dátuma:     !INV_INSTALLED!
echo   Utolsó indítás:       !INV_BOOT!
echo   Üzemidő:              !INV_UPTIMEH! óra
echo.
echo [HÁLÓZAT]
echo   Aktív adapter:        !INV_NETADAPTER!
echo   IPv4 cím:             !INV_IP!
echo   MAC cím:              !INV_MAC!
echo   Alapértelmezett GW:   !INV_GW!
echo   DNS szerverek:        !INV_DNS!
echo.
echo ========================================
echo Inventarizálás befejezve.
echo ========================================
echo.

echo Bármelyik gomb lenyomásával bezárható..
pause >nul
endlocal
exit /b
