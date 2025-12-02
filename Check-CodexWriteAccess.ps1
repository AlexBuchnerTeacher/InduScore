Write-Host "=== InduScore / VS Code – Schreibrechte Diagnose ===`n" -ForegroundColor Cyan

Write-Host "🔍 Prüfe GitHub CLI Installation..."
$gh = Get-Command gh -ErrorAction SilentlyContinue
if ($gh) {
    Write-Host "✔ GitHub CLI ist installiert: $($gh.Source)" -ForegroundColor Green
} else {
    Write-Host "❌ GitHub CLI NICHT installiert." -ForegroundColor Red
    Write-Host "➡ Bitte installieren mit: winget install GitHub.cli" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "🔍 Prüfe GitHub Auth Status..."
if ($gh) {
    gh auth status
} else {
    Write-Host "⚠ Auth-Status kann nicht geprüft werden, da CLI fehlt."
}
Write-Host ""

Write-Host "🔍 Prüfe VS Code Trusted Mode..."
$settingsPath = "$env:APPDATA\Code\User\globalStorage\state.vscdb"
$trustedFound = $false
if (Test-Path $settingsPath) {
    $lines = Get-Content $settingsPath
    foreach ($line in $lines) {
        if ($line -like "*workspace.trust*") {
            $trustedFound = $true
        }
    }
    if ($trustedFound) {
        Write-Host "✔ Workspace ist vertraut (Trusted Mode aktiv)." -ForegroundColor Green
    } else {
        Write-Host "❌ Workspace läuft wahrscheinlich im RESTRICTED MODE!" -ForegroundColor Red
        Write-Host "➡ Bitte in VS Code oben auf 'Trust' klicken." -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ Trusted-Status kann nicht geprüft werden."
}
Write-Host ""

Write-Host "🔍 Prüfe Git Repo..."
$gitFolder = "$PWD\.git"
if (Test-Path $gitFolder) {
    Write-Host "✔ Git-Repository erkannt: .git vorhanden" -ForegroundColor Green
} else {
    Write-Host "❌ KEIN echtes Git-Repository im aktuellen Ordner!" -ForegroundColor Red
    Write-Host "➡ Bitte mit 'git clone <repo>' sauber klonen." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "🔍 Prüfe Schreibrechte..."
$testFile = "$PWD\__writeTest.tmp"
$writeOk = $true
try {
    Set-Content -Path $testFile -Value "test" -ErrorAction Stop
    Remove-Item $testFile -ErrorAction SilentlyContinue
} catch {
    $writeOk = $false
}
if ($writeOk) {
    Write-Host "✔ Schreibrechte OK." -ForegroundColor Green
} else {
    Write-Host "❌ KEINE Schreibrechte im Ordner!" -ForegroundColor Red
    Write-Host "➡ Bitte Workspace als 'Trusted' markieren oder Ordner in ein Schreibverzeichnis verschieben." -ForegroundColor Yellow
}
Write-Host ""

Write-Host "🔍 Prüfe Git Branch..."
$branch = ""
try {
    $branch = git rev-parse --abbrev-ref HEAD 2>$null
} catch {
    $branch = ""
}
if ($branch -ne "") {
    Write-Host "✔ Aktueller Branch: $branch" -ForegroundColor Green
    if ($branch -eq "main" -or $branch -eq "master") {
        Write-Host "⚠ Du bist auf main – möglicherweise geschützt." -ForegroundColor Yellow
        Write-Host "➡ Empfehlung: git checkout -b feature/import"
    }
} else {
    Write-Host "⚠ Git Branch kann nicht ermittelt werden."
}

Write-Host ""
Write-Host "=== Diagnose abgeschlossen ===" -ForegroundColor Cyan
