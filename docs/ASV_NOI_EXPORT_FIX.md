# ASV NOI Export - Qualitätssicherung

## Problem
ASV (Amtliche Schulverwaltung) hat beim Import die Fehlermeldung ausgegeben:
```
org.xml.sax.SAXException: Root-Element <zeugnsnoten-import> erwartet. 
Stattdessen kam <NotenImport_Berufsschule>.
```

## Behobene Fehler

### 1. Falsches Root-Element
**Vorher:** `<NotenImport_Berufsschule>`  
**Nachher:** `<zeugnsnoten-import>`

### 2. Klasse-Attribut am falschen Ort
**Vorher:** `<zeugnsnoten-import Klasse="EAT411">`  
**Nachher:** Das Klasse-Attribut wurde vom Root-Element entfernt und als Element in die Stammdaten jedes Schülers eingefügt: `<Klasse>EAT411</Klasse>`

### 3. Vollständige Stammdaten
Jeder Schüler hat nun:
- `<ID>` - Schüler-ID
- `<Name>` - Nachname
- `<Vorname>` - Vorname
- `<Klasse>` - Klassenbezeichnung

## Korrekte XML-Struktur

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<zeugnsnoten-import
    Schuljahr="2025/26"
    Schemaversion="1.0"
    Generierungsdatum="2025-12-17">
    <Schueler>
        <Stammdaten>
            <ID>CN94OdAiuvyLE6jNvHp4</ID>
            <Name>Berger</Name>
            <Vorname>Bastian Erich</Vorname>
            <Klasse>EAT411</Klasse>
        </Stammdaten>
        <Faecher>
            <Fach>
                <Kurzform>M</Kurzform>
                <Name>Mathematik</Name>
                <Typ>BS</Typ>
                <Leistung>
                    <Schnitt_Gesamt>2.50</Schnitt_Gesamt>
                    <Zeugnisnote>3</Zeugnisnote>
                    <Anzahl_Noten>5</Anzahl_Noten>
                </Leistung>
                <Einzelnoten>
                    <Note>
                        <Wert>2</Wert>
                        <Typ>Schulaufgabe</Typ>
                        <Bezeichnung>SA 1</Bezeichnung>
                        <Gewichtung>3.0</Gewichtung>
                        <Datum>2025-10-15</Datum>
                    </Note>
                </Einzelnoten>
            </Fach>
        </Faecher>
    </Schueler>
</zeugnsnoten-import>
```

## Verwendung des Validators

Vor dem Weitergeben der XML-Datei an Kollegen:

```powershell
# XML-Datei validieren
.\validate-noi-export.ps1 -XmlFile ".\NOI_EAT411_20251217_1523.xml"
```

Der Validator prüft:
- ✓ Ist XML wohlgeformt?
- ✓ Ist Root-Element `<zeugnsnoten-import>`?
- ✓ Sind Pflichtattribute vorhanden (Schuljahr, Schemaversion, Generierungsdatum)?
- ✓ Sind Schüler-Stammdaten vollständig?
- ✓ Ist UTF-8 Encoding korrekt?

## Workflow für den Export

1. **Export in InduScore generieren**
   - Klasse auswählen
   - "NOI-Export" klicken
   - XML-Datei herunterladen

2. **Validierung durchführen**
   ```powershell
   .\validate-noi-export.ps1 -XmlFile "pfad\zur\datei.xml"
   ```

3. **Bei Erfolg**: Datei an Kollegen weitergeben ✓
4. **Bei Fehler**: Screenshot machen und Entwickler informieren ✗

## Technische Details

### Änderungen im Code
Datei: `lib/services/noi_export_service.dart`

**Zeile 37-41**: Root-Element korrigiert
```dart
buffer.writeln('<zeugnsnoten-import');
buffer.writeln('    Schuljahr="${klasse.schuljahr}"');
buffer.writeln('    Schemaversion="1.0"');
buffer.writeln('    Generierungsdatum="${dateFormat.format(now)}">');
```

**Zeile 52-53**: Klasse in Stammdaten eingefügt
```dart
buffer.writeln('            <Klasse>${_escapeXml(klasse.name)}</Klasse>');
```

**Zeile 155**: Schließendes Tag korrigiert
```dart
buffer.writeln('</zeugnsnoten-import>');
```

## Bekannte Einschränkungen

- Die offiziellen NOI-Schemas in `docs/noi-schema/` sind nur für Gymnasium (G8/G9)
- Für Berufsschulen gibt es keine offizielle XSD-Schema-Datei im Projekt
- Die Struktur basiert auf der ASV-Fehlermeldung und Best Practices

## Nächste Schritte

1. **Testing**: Export mit echten Daten testen
2. **Feedback**: Rückmeldung vom Kollegen/ASV abwarten
3. **Dokumentation**: Falls weitere Felder benötigt werden, dokumentieren
4. **Schema**: Offizielle Berufsschul-XSD von ASV besorgen (falls verfügbar)

## Support

Bei Problemen:
1. Validator-Output speichern
2. XML-Datei und Fehler-Screenshots bereitstellen
3. ASV-Version und Fehlermeldung notieren
