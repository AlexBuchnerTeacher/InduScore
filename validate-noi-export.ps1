# ASV-NOI Export Validator
# Dieses Script prüft die generierte XML-Datei auf häufige Fehler

param(
    [Parameter(Mandatory=$true)]
    [string]$XmlFile
)

Write-Host "=== ASV NOI Export Validator ===" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $XmlFile)) {
    Write-Host "FEHLER: Datei nicht gefunden: $XmlFile" -ForegroundColor Red
    exit 1
}

Write-Host "Prüfe Datei: $XmlFile" -ForegroundColor Yellow
Write-Host ""

# XML laden
try {
    [xml]$xml = Get-Content $XmlFile -Encoding UTF8
    Write-Host "[✓] XML ist wohlgeformt" -ForegroundColor Green
} catch {
    Write-Host "[✗] XML-Syntax-Fehler: $_" -ForegroundColor Red
    exit 1
}

$errors = 0
$warnings = 0

# Prüfung 1: Root-Element
Write-Host "Prüfe Root-Element..." -ForegroundColor Yellow
if ($xml.DocumentElement.LocalName -eq "zeugnsnoten-import") {
    Write-Host "[✓] Root-Element ist <zeugnsnoten-import>" -ForegroundColor Green
} elseif ($xml.DocumentElement.LocalName -eq "NotenImport_Berufsschule") {
    Write-Host "[✗] FEHLER: Root-Element ist <NotenImport_Berufsschule>, muss aber <zeugnsnoten-import> sein!" -ForegroundColor Red
    $errors++
} else {
    Write-Host "[✗] FEHLER: Unbekanntes Root-Element: $($xml.DocumentElement.LocalName)" -ForegroundColor Red
    $errors++
}

# Prüfung 2: Pflichtattribute am Root
Write-Host "Prüfe Pflichtattribute..." -ForegroundColor Yellow
$requiredAttrs = @("Schuljahr", "Schemaversion", "Generierungsdatum")
foreach ($attr in $requiredAttrs) {
    if ($xml.DocumentElement.HasAttribute($attr)) {
        $value = $xml.DocumentElement.GetAttribute($attr)
        Write-Host "[✓] Attribut '$attr' vorhanden: $value" -ForegroundColor Green
    } else {
        Write-Host "[✗] FEHLER: Pflichtattribut '$attr' fehlt!" -ForegroundColor Red
        $errors++
    }
}

# Prüfung 3: Klasse-Attribut am Root (sollte NICHT da sein!)
if ($xml.DocumentElement.HasAttribute("Klasse")) {
    Write-Host "[⚠] WARNUNG: 'Klasse'-Attribut am Root-Element gefunden - sollte in <Stammdaten> sein!" -ForegroundColor Yellow
    $warnings++
}

# Prüfung 4: Schüler-Struktur
Write-Host "Prüfe Schüler-Struktur..." -ForegroundColor Yellow
$schueler = $xml.DocumentElement.SelectNodes("//Schueler")
if ($schueler.Count -eq 0) {
    Write-Host "[✗] FEHLER: Keine <Schueler>-Elemente gefunden!" -ForegroundColor Red
    $errors++
} else {
    Write-Host "[✓] $($schueler.Count) Schüler gefunden" -ForegroundColor Green
    
    # Prüfe ersten Schüler im Detail
    $ersterschueler = $schueler[0]
    
    # Stammdaten
    if ($ersterschueler.Stammdaten) {
        Write-Host "[✓] <Stammdaten> vorhanden" -ForegroundColor Green
        
        $requiredStamm = @("ID", "Name", "Vorname")
        foreach ($feld in $requiredStamm) {
            if ($ersterschueler.Stammdaten.$feld) {
                Write-Host "  [✓] $feld : $($ersterschueler.Stammdaten.$feld)" -ForegroundColor Green
            } else {
                Write-Host "  [✗] FEHLER: $feld fehlt in Stammdaten!" -ForegroundColor Red
                $errors++
            }
        }
        
        # Prüfe Klasse in Stammdaten
        if ($ersterschueler.Stammdaten.Klasse) {
            Write-Host "  [✓] Klasse: $($ersterschueler.Stammdaten.Klasse)" -ForegroundColor Green
        } else {
            Write-Host "  [⚠] WARNUNG: Klasse fehlt in Stammdaten" -ForegroundColor Yellow
            $warnings++
        }
        
    } else {
        Write-Host "[✗] FEHLER: <Stammdaten> fehlt!" -ForegroundColor Red
        $errors++
    }
    
    # Fächer
    if ($ersterschueler.Faecher) {
        $faecher = $ersterschueler.Faecher.Fach
        if ($faecher) {
            Write-Host "[✓] $($faecher.Count) Fächer vorhanden" -ForegroundColor Green
        } else {
            Write-Host "[⚠] WARNUNG: Keine Fächer für ersten Schüler" -ForegroundColor Yellow
            $warnings++
        }
    }
}

# Prüfung 5: XML-Encoding
$firstLine = Get-Content $XmlFile -First 1 -Encoding UTF8
if ($firstLine -match 'encoding="UTF-8"') {
    Write-Host "[✓] UTF-8 Encoding korrekt" -ForegroundColor Green
} else {
    Write-Host "[⚠] WARNUNG: Encoding nicht als UTF-8 deklariert" -ForegroundColor Yellow
    $warnings++
}

# Zusammenfassung
Write-Host ""
Write-Host "=== ZUSAMMENFASSUNG ===" -ForegroundColor Cyan
Write-Host "Fehler:    $errors" -ForegroundColor $(if ($errors -eq 0) { "Green" } else { "Red" })
Write-Host "Warnungen: $warnings" -ForegroundColor $(if ($warnings -eq 0) { "Green" } else { "Yellow" })
Write-Host ""

if ($errors -eq 0) {
    Write-Host "✓ Die XML-Datei sieht gut aus und sollte von ASV akzeptiert werden!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Bitte die oben genannten Fehler beheben, bevor die Datei an ASV weitergegeben wird!" -ForegroundColor Red
    exit 1
}
