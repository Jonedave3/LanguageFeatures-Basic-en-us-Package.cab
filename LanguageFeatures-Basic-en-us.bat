@echo off
setlocal

echo ======================================================
echo  Setting English as current user language
echo ======================================================
echo.

set "LANGTAG=en-US"
set "PS1=%TEMP%\set_english_user.ps1"
set "CABDIR=%TEMP%\LangPacks"
set "CABFILE=%CABDIR%\Microsoft-Windows-LanguageFeatures-Basic-en-us-Package.cab"

REM --- Check if running as administrator ---
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo This script needs administrator privileges.
    echo Requesting administrator access...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running with administrator privileges...
echo Creating PowerShell script...

REM --- Write PowerShell script line by line ---
> "%PS1%" echo $ErrorActionPreference = "Stop"
>> "%PS1%" echo $lang = "%LANGTAG%"
>> "%PS1%" echo.
>> "%PS1%" echo function Download-LanguageCAB {
>> "%PS1%" echo     Write-Host "==== Downloading English Language Pack CABs ====" -ForegroundColor Cyan
>> "%PS1%" echo     $cabDir = "$env:TEMP\LangPacks"
>> "%PS1%" echo     if (-not (Test-Path $cabDir)) {
>> "%PS1%" echo         New-Item -ItemType Directory -Path $cabDir -Force ^| Out-Null
>> "%PS1%" echo     }
>> "%PS1%" echo.
>> "%PS1%" echo     # Define all CAB files to download
>> "%PS1%" echo     $cabFiles = @(
>> "%PS1%" echo         @{
>> "%PS1%" echo             Name = "Basic Language Features"
>> "%PS1%" echo             Url = "https://raw.githubusercontent.com/Jonedave3/LanguageFeatures-Basic-en-us-Package.cab/refs/heads/main/Microsoft-Windows-LanguageFeatures-Basic-en-us-Package~31bf3856ad364e35~amd64~~.cab"
>> "%PS1%" echo             File = "$cabDir\Microsoft-Windows-LanguageFeatures-Basic-en-us-Package.cab"
>> "%PS1%" echo         },
>> "%PS1%" echo         @{
>> "%PS1%" echo             Name = "Text-to-Speech"
>> "%PS1%" echo             Url = "https://raw.githubusercontent.com/Jonedave3/LanguageFeatures-Basic-en-us-Package.cab/refs/heads/main/Microsoft-Windows-LanguageFeatures-TextToSpeech-en-us-Package~31bf3856ad364e35~amd64~~.cab"
>> "%PS1%" echo             File = "$cabDir\Microsoft-Windows-LanguageFeatures-TextToSpeech-en-us-Package.cab"
>> "%PS1%" echo         },
>> "%PS1%" echo         @{
>> "%PS1%" echo             Name = "Speech Recognition"
>> "%PS1%" echo             Url = "https://raw.githubusercontent.com/Jonedave3/LanguageFeatures-Basic-en-us-Package.cab/refs/heads/main/Microsoft-Windows-LanguageFeatures-Speech-en-us-Package~31bf3856ad364e35~amd64~~.cab"
>> "%PS1%" echo             File = "$cabDir\Microsoft-Windows-LanguageFeatures-Speech-en-us-Package.cab"
>> "%PS1%" echo         },
>> "%PS1%" echo         @{
>> "%PS1%" echo             Name = "Language Pack"
>> "%PS1%" echo             Url = "https://raw.githubusercontent.com/Jonedave3/LanguageFeatures-Basic-en-us-Package.cab/refs/heads/main/Microsoft-Windows-Client-Language-Pack_x64_en-us.cab"
>> "%PS1%" echo             File = "$cabDir\Microsoft-Windows-Client-Language-Pack_x64_en-us.cab"
>> "%PS1%" echo         }
>> "%PS1%" echo     )
>> "%PS1%" echo.
>> "%PS1%" echo     $allSuccess = $true
>> "%PS1%" echo     $downloadedFiles = @()
>> "%PS1%" echo.
>> "%PS1%" echo     foreach ($cab in $cabFiles) {
>> "%PS1%" echo         Write-Host ""
>> "%PS1%" echo         Write-Host "Downloading: $($cab.Name)..." -ForegroundColor Cyan
>> "%PS1%" echo         Write-Host "URL: $($cab.Url)" -ForegroundColor Gray
>> "%PS1%" echo.
>> "%PS1%" echo         if (Test-Path $cab.File) {
>> "%PS1%" echo             Write-Host "  [SKIP] Already exists: $($cab.File)" -ForegroundColor Yellow
>> "%PS1%" echo             $downloadedFiles += $cab.File
>> "%PS1%" echo             continue
>> "%PS1%" echo         }
>> "%PS1%" echo.
>> "%PS1%" echo         try {
>> "%PS1%" echo             $ProgressPreference = 'SilentlyContinue'
>> "%PS1%" echo             Invoke-WebRequest -Uri $cab.Url -OutFile $cab.File -UseBasicParsing
>> "%PS1%" echo             Write-Host "  [OK] Downloaded successfully!" -ForegroundColor Green
>> "%PS1%" echo             $downloadedFiles += $cab.File
>> "%PS1%" echo         } catch {
>> "%PS1%" echo             Write-Host "  [FAIL] Download failed: $_" -ForegroundColor Red
>> "%PS1%" echo             $allSuccess = $false
>> "%PS1%" echo         }
>> "%PS1%" echo     }
>> "%PS1%" echo.
>> "%PS1%" echo     if (-not $allSuccess) {
>> "%PS1%" echo         Write-Host ""
>> "%PS1%" echo         Write-Host "Some downloads failed. Check your internet connection." -ForegroundColor Red
>> "%PS1%" echo         return @{ Success = $false; Files = $downloadedFiles }
>> "%PS1%" echo     }
>> "%PS1%" echo.
>> "%PS1%" echo     Write-Host ""
>> "%PS1%" echo     Write-Host "All language pack CABs downloaded successfully!" -ForegroundColor Green
>> "%PS1%" echo     return @{ Success = $true; Files = $downloadedFiles }
>> "%PS1%" echo }
>> "%PS1%" echo.
>> "%PS1%" echo function Install-LanguageCAB {
>> "%PS1%" echo     param([array]$cabPaths)
>> "%PS1%" echo     Write-Host "==== Installing Language Packs via DISM ====" -ForegroundColor Cyan
>> "%PS1%" echo     Write-Host "This may take 5-15 minutes..." -ForegroundColor Yellow
>> "%PS1%" echo.
>> "%PS1%" echo     $allSuccess = $true
>> "%PS1%" echo     foreach ($cabPath in $cabPaths) {
>> "%PS1%" echo         $cabName = Split-Path -Leaf $cabPath
>> "%PS1%" echo         Write-Host ""
>> "%PS1%" echo         Write-Host "Installing: $cabName" -ForegroundColor Cyan
>> "%PS1%" echo.
>> "%PS1%" echo         try {
>> "%PS1%" echo             Write-Host "  Running DISM..." -ForegroundColor Gray
>> "%PS1%" echo             $dismOutput = cmd /c "DISM /Online /Add-Package /PackagePath:`"$cabPath`" /NoRestart 2^>^&1"
>> "%PS1%" echo             $dismExitCode = $LASTEXITCODE
>> "%PS1%" echo.
>> "%PS1%" echo             if ($dismExitCode -eq 0 -or $dismExitCode -eq 3010) {
>> "%PS1%" echo                 Write-Host "  [OK] Installed successfully!" -ForegroundColor Green
>> "%PS1%" echo             } elseif ($dismExitCode -eq 1450) {
>> "%PS1%" echo                 Write-Host "  [ERROR] DISM Error 1450: Insufficient resources or incompatible package" -ForegroundColor Red
>> "%PS1%" echo                 Write-Host "  This usually means:" -ForegroundColor Yellow
>> "%PS1%" echo                 Write-Host "    - CAB file doesn't match your Windows build" -ForegroundColor Yellow
>> "%PS1%" echo                 Write-Host "    - Package is already installed" -ForegroundColor Yellow
>> "%PS1%" echo                 Write-Host "    - CAB file is corrupted" -ForegroundColor Yellow
>> "%PS1%" echo                 if ($dismOutput -match "Error") {
>> "%PS1%" echo                     Write-Host "  DISM Output: $($dismOutput -join ' ')" -ForegroundColor Gray
>> "%PS1%" echo                 }
>> "%PS1%" echo                 $allSuccess = $false
>> "%PS1%" echo             } else {
>> "%PS1%" echo                 Write-Host "  [WARN] DISM exit code: $dismExitCode" -ForegroundColor Yellow
>> "%PS1%" echo                 if ($dismOutput) {
>> "%PS1%" echo                     Write-Host "  Output: $($dismOutput -join ' ')" -ForegroundColor Gray
>> "%PS1%" echo                 }
>> "%PS1%" echo                 $allSuccess = $false
>> "%PS1%" echo             }
>> "%PS1%" echo         } catch {
>> "%PS1%" echo             Write-Host "  [FAIL] Installation error: $_" -ForegroundColor Red
>> "%PS1%" echo             $allSuccess = $false
>> "%PS1%" echo         }
>> "%PS1%" echo     }
>> "%PS1%" echo.
>> "%PS1%" echo     if ($allSuccess) {
>> "%PS1%" echo         Write-Host ""
>> "%PS1%" echo         Write-Host "All language packs installed successfully!" -ForegroundColor Green
>> "%PS1%" echo     } else {
>> "%PS1%" echo         Write-Host ""
>> "%PS1%" echo         Write-Host "Some packages failed to install. Continuing anyway..." -ForegroundColor Yellow
>> "%PS1%" echo     }
>> "%PS1%" echo     return $allSuccess
>> "%PS1%" echo }
>> "%PS1%" echo.
>> "%PS1%" echo try {
>> "%PS1%" echo     Write-Host "==== Step 1: Checking if English language pack is installed ====" -ForegroundColor Cyan
>> "%PS1%" echo     $list = Get-WinUserLanguageList
>> "%PS1%" echo     $isInstalled = $list.LanguageTag -contains $lang
>> "%PS1%" echo.
>> "%PS1%" echo     if (-not $isInstalled) {
>> "%PS1%" echo         Write-Host "English language pack is NOT installed." -ForegroundColor Yellow
>> "%PS1%" echo.
>> "%PS1%" echo         # Check if Install-Language cmdlet exists
>> "%PS1%" echo         $hasInstallLanguage = Get-Command Install-Language -ErrorAction SilentlyContinue
>> "%PS1%" echo.
>> "%PS1%" echo         if ($hasInstallLanguage) {
>> "%PS1%" echo             Write-Host "Attempting automatic installation via Install-Language..." -ForegroundColor Cyan
>> "%PS1%" echo             try {
>> "%PS1%" echo                 Install-Language -Language $lang -IncludeAllSubpackages -CopyToSettings
>> "%PS1%" echo                 Write-Host "English language pack installed successfully!" -ForegroundColor Green
>> "%PS1%" echo             } catch {
>> "%PS1%" echo                 Write-Host "Install-Language failed: $_" -ForegroundColor Red
>> "%PS1%" echo                 throw
>> "%PS1%" echo             }
>> "%PS1%" echo         } else {
>> "%PS1%" echo             Write-Host "Install-Language cmdlet not available (LTSC/Server edition detected)." -ForegroundColor Yellow
>> "%PS1%" echo             Write-Host "Switching to CAB download and DISM installation method..." -ForegroundColor Cyan
>> "%PS1%" echo.
>> "%PS1%" echo             # Download all required CAB files
>> "%PS1%" echo             $downloadResult = Download-LanguageCAB
>> "%PS1%" echo             if (-not $downloadResult.Success) {
>> "%PS1%" echo                 throw "Failed to download all required language pack CAB files."
>> "%PS1%" echo             }
>> "%PS1%" echo.
>> "%PS1%" echo             # Install all downloaded CAB files
>> "%PS1%" echo             $installSuccess = Install-LanguageCAB -cabPaths $downloadResult.Files
>> "%PS1%" echo             if (-not $installSuccess) {
>> "%PS1%" echo                 Write-Host "Warning: Some packages failed, but continuing..." -ForegroundColor Yellow
>> "%PS1%" echo             }
>> "%PS1%" echo.
>> "%PS1%" echo             # Refresh language list after installation
>> "%PS1%" echo             Write-Host "Refreshing language list..." -ForegroundColor Cyan
>> "%PS1%" echo             Start-Sleep -Seconds 3
>> "%PS1%" echo             $list = Get-WinUserLanguageList
>> "%PS1%" echo         }
>> "%PS1%" echo     } else {
>> "%PS1%" echo         Write-Host "English language pack is already installed." -ForegroundColor Green
>> "%PS1%" echo     }
>> "%PS1%" echo.
>> "%PS1%" echo     Write-Host "==== Step 2: Setting English as primary user language ====" -ForegroundColor Cyan
>> "%PS1%" echo     $cur = $list[0].LanguageTag
>> "%PS1%" echo     Write-Host "Current primary language: $cur"
>> "%PS1%" echo.
>> "%PS1%" echo     if ($cur -ne $lang) {
>> "%PS1%" echo         Write-Host "Reordering list to make $lang primary..."
>> "%PS1%" echo         $otherLangs = $list ^| Where-Object { $_.LanguageTag -ne $lang }
>> "%PS1%" echo         $primaryLang = $list ^| Where-Object { $_.LanguageTag -eq $lang }
>> "%PS1%" echo         $finalList = @($primaryLang) + @($otherLangs)
>> "%PS1%" echo         Set-WinUserLanguageList -LanguageList $finalList -Force
>> "%PS1%" echo         Write-Host "$lang is now the primary language." -ForegroundColor Green
>> "%PS1%" echo     } else {
>> "%PS1%" echo         Write-Host "Already using $lang as primary language." -ForegroundColor Green
>> "%PS1%" echo     }
>> "%PS1%" echo.
>> "%PS1%" echo     Set-WinUILanguageOverride -Language $lang
>> "%PS1%" echo     Write-Host ""
>> "%PS1%" echo     Write-Host "==== Updated User Language List ====" -ForegroundColor Cyan
>> "%PS1%" echo     Get-WinUserLanguageList ^| ForEach-Object { Write-Host "  - $($_.LanguageTag)" }
>> "%PS1%" echo.
>> "%PS1%" echo     Write-Host "================================================" -ForegroundColor Green
>> "%PS1%" echo     Write-Host "SUCCESS! English has been set as your language." -ForegroundColor Green
>> "%PS1%" echo     Write-Host "Sign out and sign back in for changes to take full effect." -ForegroundColor Yellow
>> "%PS1%" echo     Write-Host "You may also need to restart for language features to fully activate." -ForegroundColor Yellow
>> "%PS1%" echo     Write-Host "================================================" -ForegroundColor Green
>> "%PS1%" echo.
>> "%PS1%" echo ^} catch ^{
>> "%PS1%" echo     Write-Host ""
>> "%PS1%" echo     Write-Host "================================================" -ForegroundColor Red
>> "%PS1%" echo     Write-Host "ERROR: $_" -ForegroundColor Red
>> "%PS1%" echo     Write-Host "================================================" -ForegroundColor Red
>> "%PS1%" echo     exit 1
>> "%PS1%" echo ^}

REM --- Run PowerShell script ---
powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
set "PSERROR=%ERRORLEVEL%"

REM --- Clean up PowerShell script ---
del "%PS1%" >nul 2>&1

if %PSERROR% NEQ 0 (
    echo.
    echo Script encountered an error. See message above.
    echo.
)

echo.
pause
endlocal
