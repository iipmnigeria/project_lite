$ErrorActionPreference = "Stop"
$ProjectRoot = Split-Path -Parent $PSScriptRoot
$MinimumNodeMajor = 18

function Write-Step([string]$Message) {
    Write-Host "`n>> $Message" -ForegroundColor Cyan
}

function Test-Node {
    try {
        $versionText = (& node --version 2>$null)
        if (-not $versionText) { return $false }
        $major = [int](($versionText -replace '^v','').Split('.')[0])
        return $major -ge $MinimumNodeMajor
    } catch { return $false }
}

function Refresh-Path {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

Write-Host "ProjectLite will check the required software and prepare the app." -ForegroundColor White

if (-not (Test-Node)) {
    Write-Step "Node.js LTS is required but was not detected."
    $winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Host "Windows Package Manager was found. Node.js LTS will now be installed."
        Write-Host "Windows may request permission to continue." -ForegroundColor Yellow
        & winget install --id OpenJS.NodeJS.LTS --exact --source winget --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -ne 0) {
            throw "Windows Package Manager could not install Node.js. Install Node.js LTS from https://nodejs.org and run RUN_PROJECTLITE.bat again."
        }
        Refresh-Path
    } else {
        Write-Host "Automatic installation is not available on this computer." -ForegroundColor Yellow
        Write-Host "The official Node.js download page will open. Install the LTS version, then run this launcher again."
        Start-Process "https://nodejs.org/en/download"
        Read-Host "Press Enter after Node.js has finished installing"
        Refresh-Path
    }
}

if (-not (Test-Node)) {
    throw "Node.js 18 or later is still unavailable. Restart Windows if it was just installed, then run RUN_PROJECTLITE.bat again."
}

Write-Host "Node.js $(& node --version) is available." -ForegroundColor Green

$NpmCommand = Get-Command npm.cmd -ErrorAction SilentlyContinue
if (-not $NpmCommand) {
    throw "npm.cmd was not found even though Node.js is installed. Restart Windows, then run RUN_PROJECTLITE.bat again."
}
$NpmPath = $NpmCommand.Source

Set-Location $ProjectRoot
if (-not (Test-Path (Join-Path $ProjectRoot 'package.json'))) {
    throw "The ProjectLite package.json file was not found. Keep RUN_PROJECTLITE.bat inside the extracted projectlite folder."
}

$LockFile = Join-Path $ProjectRoot 'package-lock.json'
$InstallMarker = Join-Path $ProjectRoot '.projectlite-installed'
$CurrentLockHash = if (Test-Path $LockFile) { (Get-FileHash $LockFile -Algorithm SHA256).Hash } else { '' }
$SavedLockHash = if (Test-Path $InstallMarker) { (Get-Content $InstallMarker -Raw).Trim() } else { '' }
$NeedsInstall = (-not (Test-Path (Join-Path $ProjectRoot 'node_modules'))) -or ($CurrentLockHash -ne $SavedLockHash)

if ($NeedsInstall) {
    Write-Step "Installing ProjectLite components (internet connection required for the first run)."
    & $NpmPath install
    if ($LASTEXITCODE -ne 0) { throw "ProjectLite component installation failed. Check your internet connection and try again." }
    Set-Content -Path $InstallMarker -Value $CurrentLockHash -Encoding ASCII
} else {
    Write-Host "ProjectLite components are already installed." -ForegroundColor Green
}

Write-Step "Starting ProjectLite"
$Url = "http://localhost:5173"
Write-Host "The app will open at $Url" -ForegroundColor Green
Write-Host "Keep this window open while using ProjectLite. Press Ctrl+C to stop it." -ForegroundColor DarkGray

$server = $null
try {
    $server = Start-Process -FilePath $NpmPath -ArgumentList @('run','dev','--','--host','127.0.0.1') -WorkingDirectory $ProjectRoot -PassThru -NoNewWindow
    $ready = $false
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        Start-Sleep -Seconds 1
        if ($server.HasExited) {
            throw "The ProjectLite server stopped during startup. Review the error shown above."
        }
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 2
            if ($response.StatusCode -ge 200 -and $response.StatusCode -lt 500) {
                $ready = $true
                break
            }
        } catch {
            Write-Host "." -NoNewline -ForegroundColor DarkGray
        }
    }
    if (-not $ready) {
        throw "ProjectLite did not become available within 30 seconds. Check whether security software is blocking Node.js on localhost."
    }
    Write-Host "`nProjectLite is ready." -ForegroundColor Green
    Start-Process $Url
    Wait-Process -Id $server.Id
} finally {
    if ($server -and -not $server.HasExited) {
        Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue
    }
}
