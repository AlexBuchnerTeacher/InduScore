import 'package:flutter/foundation.dart';
import '../models/student.dart';
import '../models/klasse.dart';
import '../models/subject.dart';
import '../models/app_user.dart';
import '../models/schueler_unterricht.dart';
import '../models/beruf.dart';
import 'firestore_service.dart';

/// ASV Import Service
/// 
/// Importiert Schülerdaten aus ASV-CSV-Exporten (Amtliche Schulverwaltung Bayern).
/// Legt automatisch Klassen, Fächer, Lehrer und Schüler an.
/// Speichert Unterrichts-Beziehungen (Schüler-Fach-Lehrer).
class AsvImportService {
  final FirestoreService _firestoreService;

  AsvImportService(this._firestoreService);

  /// ASV-Spalten-Header (für Format-Erkennung)
  static const List<String> asvHeaders = [
    'lokales Differenzierungsmerkmal',
    'Familienname',
    'Vornamen',
    'Klasse',
    'M/W.Kurzform',
    'Religionszugehörigkeit.Kurzform',
  ];

  /// Prüft ob die CSV-Datei ein ASV-Format hat
  static bool isAsvFormat(List<String> headers) {
    // Mindestens 3 ASV-typische Header müssen vorhanden sein
    int matches = 0;
    for (final header in asvHeaders) {
      if (headers.any((h) => h.trim() == header)) {
        matches++;
      }
    }
    return matches >= 3;
  }

  /// Parst eine ASV-CSV-Zeile (Semikolon-getrennt, mit Anführungszeichen)
  static List<String> parseAsvLine(String line) {
    final List<String> result = [];
    bool inQuotes = false;
    StringBuffer current = StringBuffer();

    for (int i = 0; i < line.length; i++) {
      final char = line[i];

      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ';' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(char);
      }
    }
    result.add(current.toString().trim());

    return result;
  }

  /// Parst eine komplette ASV-CSV-Datei
  static AsvParseResult parseAsvCsv(String csvContent) {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) {
      return AsvParseResult(error: 'CSV-Datei ist leer');
    }

    final headers = parseAsvLine(lines.first);
    if (!isAsvFormat(headers)) {
      return AsvParseResult(error: 'Kein ASV-Format erkannt');
    }

    // Header-Indizes finden
    final headerMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      headerMap[headers[i]] = i;
    }

    final rows = <AsvRow>[];
    for (int i = 1; i < lines.length; i++) {
      final values = parseAsvLine(lines[i]);
      if (values.length < headers.length) continue;

      final row = AsvRow(
        asvId: _getValue(values, headerMap, 'lokales Differenzierungsmerkmal'),
        nachname: _getValue(values, headerMap, 'Familienname'),
        vorname: _getValue(values, headerMap, 'Vornamen'),
        klasse: _getValue(values, headerMap, 'Klasse'),
        geschlecht: _getValue(values, headerMap, 'M/W.Kurzform'),
        religion: _getValue(values, headerMap, 'Religionszugehörigkeit.Kurzform'),
        email: _getValue(values, headerMap, 'Schüler/in E-Mail'),
        ausbildungsbetrieb: _getValue(values, headerMap, 'Ausb. Betrieb Name1'),
        austrittsDatum: _getValue(values, headerMap, 'Austritt am (voraussichtlich)'),
        befreiungDeutsch: _getValue(values, headerMap, 'Befreiung Deutsch') == 'ja',
        befreiungPuG: _getValue(values, headerMap, 'Befreiung Politik und Gesellschaft') == 'ja',
        lehrerFaecher: _getValue(values, headerMap, 'Alle Lehrkräfte (Kürzel) mit Fach'),
        unterricht: _getValue(values, headerMap, 'besuchter Unterricht des Schülers/der Schülerin mit Bezeichnung, Fach, Lehrer'),
      );

      if (row.nachname.isNotEmpty && row.vorname.isNotEmpty) {
        rows.add(row);
      }
    }

    return AsvParseResult(rows: rows, headers: headers);
  }

  static String _getValue(List<String> values, Map<String, int> headerMap, String header) {
    final index = headerMap[header];
    if (index == null || index >= values.length) return '';
    return values[index];
  }

  /// Extrahiert Lehrer-Informationen aus dem Unterrichtsfeld
  /// Format: "FU-IT_1/EAT411*1 IT-Systeme Schmidt, ..."
  static List<UnterrichtInfo> parseUnterricht(String unterricht) {
    if (unterricht.isEmpty) return [];

    final result = <UnterrichtInfo>[];
    final parts = unterricht.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);

    for (final part in parts) {
      // Format: "FU-IT_1/EAT411*1 IT-Systeme Schmidt"
      final match = RegExp(r'^([A-Za-z\-]+)_(\d+)/([A-Z]+\d+)\*\d+\s+(.+?)\s+(\w+)$').firstMatch(part);
      if (match != null) {
        String fachKuerzel = match.group(1)!;
        final gruppe = match.group(2)!;
        final fachName = match.group(4)!;
        final lehrerName = match.group(5)!;

        // FU- Präfix entfernen
        if (fachKuerzel.startsWith('FU-')) {
          fachKuerzel = fachKuerzel.substring(3);
        }

        result.add(UnterrichtInfo(
          fachKuerzel: fachKuerzel,
          fachName: fachName,
          lehrerName: lehrerName,
          gruppe: '${fachKuerzel}_$gruppe',
        ));
      }
    }

    return result;
  }

  /// Extrahiert Lehrer-Kürzel aus dem Kürzel-Feld
  /// Format: "SDT FU-IT, NU FU-IT, BER FU-IT, WEN E, ..."
  static Map<String, Set<String>> parseLehrerKuerzel(String lehrerFaecher) {
    final result = <String, Set<String>>{}; // Kürzel -> Set<Fach>
    
    if (lehrerFaecher.isEmpty) return result;
    
    final parts = lehrerFaecher.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty);
    
    for (final part in parts) {
      final spaceIndex = part.indexOf(' ');
      if (spaceIndex > 0) {
        final kuerzel = part.substring(0, spaceIndex);
        String fach = part.substring(spaceIndex + 1);
        
        // FU- Präfix entfernen
        if (fach.startsWith('FU-')) {
          fach = fach.substring(3);
        }
        
        result.putIfAbsent(kuerzel, () => <String>{});
        result[kuerzel]!.add(fach);
      }
    }
    
    return result;
  }

  /// Führt den kompletten ASV-Import durch
  Future<AsvImportResult> importAsvData(AsvParseResult parseResult) async {
    if (parseResult.error != null) {
      return AsvImportResult(error: parseResult.error);
    }

    final stats = AsvImportStats();
    
    try {
      // 1. Alle existierenden Daten laden
      final existingKlassen = await _firestoreService.getKlassenOnce();
      final existingSubjects = await _firestoreService.getSubjectsOnce();
      final existingUsers = await _firestoreService.getAppUsersOnce();
      final existingStudents = await _firestoreService.getStudentsOnce();
      
      // Maps für schnellen Zugriff (shortName als Kürzel)
      final klassenByName = {for (var k in existingKlassen) k.name: k};
      final subjectsByKuerzel = {for (var s in existingSubjects) if (s.shortName != null) s.shortName!: s};
      final usersByKuerzel = {for (var u in existingUsers) u.kuerzel: u};
      final studentsByAsvId = {for (var s in existingStudents) if (s.asvId != null) s.asvId!: s};
      
      // Neue Entitäten sammeln
      final newKlassen = <String, Klasse>{};
      final newSubjects = <String, Subject>{};
      final newUsers = <String, AppUser>{};
      final unterrichtToCreate = <SchuelerUnterricht>[];

      // 2. Durch alle Zeilen iterieren
      for (final row in parseResult.rows!) {
        // 2a. Klasse anlegen/finden
        Klasse klasse;
        if (klassenByName.containsKey(row.klasse)) {
          klasse = klassenByName[row.klasse]!;
        } else if (newKlassen.containsKey(row.klasse)) {
          klasse = newKlassen[row.klasse]!;
        } else {
          // Neue Klasse anlegen - Klassenname parsen (z.B. "EAT411")
          try {
            final parsed = ParsedKlassenname.parse(row.klasse);
            final now = DateTime.now();
            klasse = Klasse(
              id: '', // wird von Firestore generiert
              beruf: parsed.beruf,
              jahrgangsstufe: parsed.jahrgangsstufe,
              zeitgruppe: parsed.zeitgruppe,
              laufendeNummer: parsed.laufendeNummer,
              schuljahr: Schuljahr.current(),
              createdAt: now,
              updatedAt: now,
            );
            final newId = await _firestoreService.createKlasse(klasse);
            klasse = klasse.copyWith(id: newId);
            newKlassen[row.klasse] = klasse;
            klassenByName[row.klasse] = klasse;
            stats.klassenNeu++;
          } catch (e) {
            debugPrint('Fehler beim Parsen der Klasse ${row.klasse}: $e');
            continue; // Überspringe diesen Schüler
          }
        }

        // 2b. Unterricht parsen und Fächer/Lehrer anlegen
        final unterrichtInfos = parseUnterricht(row.unterricht);
        final lehrerKuerzelMap = parseLehrerKuerzel(row.lehrerFaecher);
        
        for (final info in unterrichtInfos) {
          // Fach anlegen/finden (shortName als Kürzel verwenden)
          Subject subject;
          if (subjectsByKuerzel.containsKey(info.fachKuerzel)) {
            subject = subjectsByKuerzel[info.fachKuerzel]!;
          } else if (newSubjects.containsKey(info.fachKuerzel)) {
            subject = newSubjects[info.fachKuerzel]!;
          } else {
            // Neues Fach anlegen - shortName = Kürzel
            // Beruf aus der aktuellen Klasse ableiten
            final parsed = ParsedKlassenname.parse(row.klasse);
            subject = Subject(
              id: '',
              name: info.fachName,
              shortName: info.fachKuerzel,
              typ: FachTyp.beruflich, // Default: Beruflich
              berufe: [parsed.beruf],
              createdAt: DateTime.now(),
            );
            final newId = await _firestoreService.createSubject(subject);
            subject = subject.copyWith(id: newId);
            newSubjects[info.fachKuerzel] = subject;
            subjectsByKuerzel[info.fachKuerzel] = subject;
            stats.faecherNeu++;
          }

          // Lehrer-Kürzel aus dem Kürzel-Feld finden
          String? lehrerKuerzel;
          for (final entry in lehrerKuerzelMap.entries) {
            if (entry.value.contains(info.fachKuerzel)) {
              lehrerKuerzel = entry.key;
              break;
            }
          }

          // Lehrer anlegen/finden
          AppUser? lehrer;
          if (lehrerKuerzel != null) {
            if (usersByKuerzel.containsKey(lehrerKuerzel)) {
              lehrer = usersByKuerzel[lehrerKuerzel]!;
            } else if (newUsers.containsKey(lehrerKuerzel)) {
              lehrer = newUsers[lehrerKuerzel]!;
            } else {
              // Neuen Lehrer anlegen
              lehrer = AppUser(
                id: '',
                email: '${lehrerKuerzel.toLowerCase()}@schule.de', // Placeholder
                name: info.lehrerName,
                kuerzel: lehrerKuerzel,
                rolle: UserRole.lehrer,
                createdAt: DateTime.now(),
              );
              final newId = await _firestoreService.createAppUser(lehrer);
              lehrer = lehrer.copyWith(id: newId);
              newUsers[lehrerKuerzel] = lehrer;
              usersByKuerzel[lehrerKuerzel] = lehrer;
              stats.lehrerNeu++;
            }
          }
        }

        // 2c. Schüler anlegen/aktualisieren
        Student student;
        final now = DateTime.now();
        
        // Austrittsdatum parsen
        DateTime? austrittsDatum;
        if (row.austrittsDatum.isNotEmpty) {
          try {
            final parts = row.austrittsDatum.split('.');
            if (parts.length == 3) {
              austrittsDatum = DateTime(
                int.parse(parts[2]),
                int.parse(parts[1]),
                int.parse(parts[0]),
              );
            }
          } catch (e) {
            debugPrint('Fehler beim Parsen des Austrittsdatums: ${row.austrittsDatum}');
          }
        }

        // Status bestimmen
        final status = (austrittsDatum != null && austrittsDatum.isBefore(now))
            ? StudentStatus.ausgetreten
            : StudentStatus.aktiv;

        if (studentsByAsvId.containsKey(row.asvId)) {
          // Schüler aktualisieren
          final existing = studentsByAsvId[row.asvId]!;
          student = existing.copyWith(
            firstName: row.vorname,
            lastName: row.nachname,
            klasseId: klasse.id,
            geschlecht: row.geschlecht,
            religion: row.religion,
            email: row.email,
            ausbildungsbetrieb: row.ausbildungsbetrieb,
            befreiungDeutsch: row.befreiungDeutsch,
            befreiungPuG: row.befreiungPuG,
            austrittsDatum: austrittsDatum,
            status: status,
          );
          await _firestoreService.updateStudent(student);
          stats.schuelerAktualisiert++;
        } else {
          // Neuen Schüler anlegen
          student = Student(
            id: '',
            firstName: row.vorname,
            lastName: row.nachname,
            klasseId: klasse.id,
            eintrittsDatum: now,
            austrittsDatum: austrittsDatum,
            status: status,
            createdAt: now,
            asvId: row.asvId,
            geschlecht: row.geschlecht,
            religion: row.religion,
            email: row.email,
            ausbildungsbetrieb: row.ausbildungsbetrieb,
            befreiungDeutsch: row.befreiungDeutsch,
            befreiungPuG: row.befreiungPuG,
          );
          final newId = await _firestoreService.createStudent(student);
          student = student.copyWith(id: newId);
          stats.schuelerNeu++;
        }

        // 2d. Unterrichts-Beziehungen erstellen
        for (final info in unterrichtInfos) {
          final subject = subjectsByKuerzel[info.fachKuerzel];
          
          // Lehrer finden
          String? lehrerKuerzel;
          for (final entry in lehrerKuerzelMap.entries) {
            if (entry.value.contains(info.fachKuerzel)) {
              lehrerKuerzel = entry.key;
              break;
            }
          }
          final lehrer = lehrerKuerzel != null ? usersByKuerzel[lehrerKuerzel] : null;

          if (subject != null && lehrer != null) {
            unterrichtToCreate.add(SchuelerUnterricht(
              id: '',
              studentId: student.id,
              subjectId: subject.id,
              lehrerId: lehrer.id,
              gruppe: info.gruppe,
              klasseId: klasse.id,
              createdAt: now,
            ));
          }
        }
      }

      // 3. Unterrichts-Beziehungen speichern (ohne Duplikate)
      final existingUnterricht = await _firestoreService.getSchuelerUnterrichtOnce();
      final existingKeys = existingUnterricht.map((u) => u.uniqueKey).toSet();

      for (final unterricht in unterrichtToCreate) {
        if (!existingKeys.contains(unterricht.uniqueKey)) {
          await _firestoreService.createSchuelerUnterricht(unterricht);
          existingKeys.add(unterricht.uniqueKey);
          stats.beziehungenNeu++;
        }
      }

      return AsvImportResult(stats: stats);
    } catch (e) {
      return AsvImportResult(error: 'Import-Fehler: $e');
    }
  }
}

/// Eine geparste ASV-Zeile
class AsvRow {
  final String asvId;
  final String nachname;
  final String vorname;
  final String klasse;
  final String geschlecht;
  final String religion;
  final String email;
  final String ausbildungsbetrieb;
  final String austrittsDatum;
  final bool befreiungDeutsch;
  final bool befreiungPuG;
  final String lehrerFaecher;
  final String unterricht;

  AsvRow({
    required this.asvId,
    required this.nachname,
    required this.vorname,
    required this.klasse,
    required this.geschlecht,
    required this.religion,
    required this.email,
    required this.ausbildungsbetrieb,
    required this.austrittsDatum,
    required this.befreiungDeutsch,
    required this.befreiungPuG,
    required this.lehrerFaecher,
    required this.unterricht,
  });
}

/// Ergebnis des CSV-Parsens
class AsvParseResult {
  final List<AsvRow>? rows;
  final List<String>? headers;
  final String? error;

  AsvParseResult({this.rows, this.headers, this.error});

  bool get isValid => error == null && rows != null && rows!.isNotEmpty;
  int get rowCount => rows?.length ?? 0;
}

/// Unterrichts-Info aus dem ASV-Feld
class UnterrichtInfo {
  final String fachKuerzel;
  final String fachName;
  final String lehrerName;
  final String gruppe;

  UnterrichtInfo({
    required this.fachKuerzel,
    required this.fachName,
    required this.lehrerName,
    required this.gruppe,
  });
}

/// Import-Statistiken
class AsvImportStats {
  int schuelerNeu = 0;
  int schuelerAktualisiert = 0;
  int klassenNeu = 0;
  int faecherNeu = 0;
  int lehrerNeu = 0;
  int beziehungenNeu = 0;

  @override
  String toString() {
    return '''
Import abgeschlossen:
- Schüler: $schuelerNeu neu, $schuelerAktualisiert aktualisiert
- Klassen: $klassenNeu neu
- Fächer: $faecherNeu neu
- Lehrer: $lehrerNeu neu
- Beziehungen: $beziehungenNeu neu
''';
  }
}

/// Ergebnis des Imports
class AsvImportResult {
  final AsvImportStats? stats;
  final String? error;

  AsvImportResult({this.stats, this.error});

  bool get isSuccess => error == null && stats != null;
}
