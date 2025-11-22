import 'package:cloud_firestore/cloud_firestore.dart';
import 'beruf.dart';

/// Klasse an der Berufsschule
/// Format: "EAT321" (Beruf + Jahrgangsstufe + Zeitgruppe + Laufende Nummer)
class Klasse {
  final String id;
  final Beruf beruf;
  final int jahrgangsstufe; // 1, 2, 3, 4 (statt 10, 11, 12, 13)
  final Zeitgruppe zeitgruppe;
  final int laufendeNummer; // 1, 2, 3, ...
  final Schuljahr schuljahr;
  final DateTime createdAt;
  final DateTime updatedAt;

  Klasse({
    required this.id,
    required this.beruf,
    required this.jahrgangsstufe,
    required this.zeitgruppe,
    required this.laufendeNummer,
    required this.schuljahr,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Klassenname: "EAT321"
  String get name =>
      '${beruf.code}$jahrgangsstufe${zeitgruppe.nummer}$laufendeNummer';

  /// VollstÃ¤ndiger Name mit Schuljahr: "EAT321 (2024/25)"
  String get fullName => '$name ($schuljahr)';

  // Firestore Serialization
  factory Klasse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    Schuljahr parsedSchuljahr;
    try {
      parsedSchuljahr = Schuljahr.fromString(data['schuljahr'] as String);
    } catch (_) {
      parsedSchuljahr = Schuljahr.current();
    }

    return Klasse(
      id: doc.id,
      beruf: Beruf.fromCode(data['beruf'] as String),
      jahrgangsstufe: data['jahrgangsstufe'] as int,
      zeitgruppe: Zeitgruppe.fromNummer(data['zeitgruppe'] as int),
      laufendeNummer: data['laufendeNummer'] as int,
      schuljahr: parsedSchuljahr,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'beruf': beruf.code,
      'jahrgangsstufe': jahrgangsstufe,
      'zeitgruppe': zeitgruppe.nummer,
      'laufendeNummer': laufendeNummer,
      'schuljahr': schuljahr.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Klasse copyWith({
    String? id,
    Beruf? beruf,
    int? jahrgangsstufe,
    Zeitgruppe? zeitgruppe,
    int? laufendeNummer,
    Schuljahr? schuljahr,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Klasse(
      id: id ?? this.id,
      beruf: beruf ?? this.beruf,
      jahrgangsstufe: jahrgangsstufe ?? this.jahrgangsstufe,
      zeitgruppe: zeitgruppe ?? this.zeitgruppe,
      laufendeNummer: laufendeNummer ?? this.laufendeNummer,
      schuljahr: schuljahr ?? this.schuljahr,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Parsed representation of a Klassenname (z.B. "EAT321").
class ParsedKlassenname {
  final Beruf beruf;
  final int jahrgangsstufe;
  final Zeitgruppe zeitgruppe;
  final int laufendeNummer;

  const ParsedKlassenname({
    required this.beruf,
    required this.jahrgangsstufe,
    required this.zeitgruppe,
    required this.laufendeNummer,
  });

  /// Wirft FormatException mit klaren Hinweisen bei ungÃ¼ltigem Format.
  static ParsedKlassenname parse(String input) {
    final value = input.trim().toUpperCase();
    final match = RegExp(r'^(IE|EAT|EBT|EGS)(\d)(\d)(\d)$').firstMatch(value);
    if (match == null) {
      throw const FormatException(
        'Format: <Beruf><Stufe><Zeitgruppe><Nummer>, z.B. EAT321',
      );
    }

    final beruf = Beruf.fromCode(match.group(1)!);
    final stufe = int.parse(match.group(2)!);
    final zeitgruppe = Zeitgruppe.fromNummer(int.parse(match.group(3)!));
    final nummer = int.parse(match.group(4)!);

    if (stufe < 1 || stufe > 4) {
      throw const FormatException('Jahrgangsstufe muss 1-4 sein');
    }

    return ParsedKlassenname(
      beruf: beruf,
      jahrgangsstufe: stufe,
      zeitgruppe: zeitgruppe,
      laufendeNummer: nummer,
    );
  }
}
