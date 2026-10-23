@echo off
setlocal
title Bettbox Portable Cleanup Tool

cd /d "%~dp0"
set "APP_DIR=%~dp0"
set "CLEAN_SCRIPT=%~f0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath $env:CLEAN_SCRIPT -Verb RunAs"
    exit /b
)

echo ========================================================
echo             Bettbox Portable Cleanup Tool
echo ========================================================
echo.
echo Only items that belong to this folder will be cleaned:
echo   %APP_DIR%
echo.
echo  1. Terminate Bettbox processes started from this folder
echo  2. Remove helper services installed from this folder
echo  3. Remove scheduled startup tasks pointing to this folder
echo  4. Remove URL protocol handlers pointing to this folder
echo  5. Reset the system proxy if it points to localhost
echo  6. Remove leftover Wintun adapters when no other Bettbox is running
echo.
set /p CONFIRM="Are you sure you want to clean up system traces? (Y/N): "
if /i not "%CONFIRM%"=="Y" (
    echo.
    echo Operation cancelled by user.
    pause
    exit /b
)

echo.
set /p CLEAN_DATA="Do you also want to delete the portable data folder? (Y/N): "
echo.

echo [1/6] Cleaning helper services...
powershell -NoProfile -Command "$d = $env:APP_DIR; Get-CimInstance Win32_Service -ErrorAction SilentlyContinue | Where-Object { $_.PathName -and $_.PathName.Trim().Trim([char]34).StartsWith($d, [StringComparison]::OrdinalIgnoreCase) } | ForEach-Object { Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue; sc.exe delete $_.Name | Out-Null }" >nul 2>&1

echo [2/6] Terminating running processes...
powershell -NoProfile -Command "$d = $env:APP_DIR; Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.Path -and $_.Path.StartsWith($d, [StringComparison]::OrdinalIgnoreCase) } | Stop-Process -Force -ErrorAction SilentlyContinue" >nul 2>&1

echo [3/6] Cleaning scheduled tasks...
powershell -NoProfile -Command "$d = $env:APP_DIR; Get-ScheduledTask -ErrorAction SilentlyContinue | Where-Object { @($_.Actions | Where-Object { $_.Execute -and $_.Execute.Trim().Trim([char]34).StartsWith($d, [StringComparison]::OrdinalIgnoreCase) }).Count -gt 0 } | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue" >nul 2>&1

echo [4/6] Cleaning URL protocol handlers...
powershell -NoProfile -Command "$d = $env:APP_DIR; foreach ($s in 'clash','clashmeta','flclash','bettbox') { $k = 'HKCU:\Software\Classes\' + $s; $c = (Get-ItemProperty -Path ($k + '\shell\open\command') -ErrorAction SilentlyContinue).'(default)'; if ($c -and $c.Trim().Trim([char]34).StartsWith($d, [StringComparison]::OrdinalIgnoreCase)) { Remove-Item -Path $k -Recurse -Force -ErrorAction SilentlyContinue } }" >nul 2>&1

echo [5/6] Checking system proxy settings...
powershell -NoProfile -Command "$k = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'; $p = Get-ItemProperty -Path $k -ErrorAction SilentlyContinue; if ($p.ProxyEnable -eq 1 -and $p.ProxyServer -and ($p.ProxyServer.StartsWith('127.0.0.1') -or $p.ProxyServer.StartsWith('localhost'))) { Set-ItemProperty -Path $k -Name ProxyEnable -Value 0; Remove-ItemProperty -Path $k -Name ProxyServer -ErrorAction SilentlyContinue }" >nul 2>&1

echo [6/6] Cleaning virtual network adapters...
powershell -NoProfile -Command "if (@(Get-Process -Name 'BettboxCore','BettboxDevCore' -ErrorAction SilentlyContinue).Count -eq 0) { Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.InterfaceDescription -like '*Bettbox*' -or $_.Name -like '*Bettbox*' } | ForEach-Object { Disable-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue; Remove-NetAdapter -Name $_.Name -Confirm:$false -ErrorAction SilentlyContinue } }" >nul 2>&1

if /i "%CLEAN_DATA%"=="Y" (
    echo.
    echo Cleaning portable data folder...
    if exist "portable" (
        rd /s /q "portable" >nul 2>&1
    )
    mkdir "portable" >nul 2>&1
    type nul > "portable\.keep"
)

echo.
echo ========================================================
echo       Cleanup completed! System traces removed.
echo ========================================================
echo.
pause
