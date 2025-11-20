import 'package:cloud_firestore/cloud_firestore.dart';

/// Art des Leistungsnachweises
enum LeistungsnachweisTyp {
  schulaufgabe('Schulaufgabe', 2.0), // Gewichtung 2:1
  stegreifaufgabe('Stegreifaufgabe', 1.0),
  muendlich('Mündliche Note', 1.0),
  praktisch('Praktische Arbeit', 1.5),
  projekt('Projekt', 2.0),
  sonstiges('Sonstiges', 1.0);

  final String name;
  final double gewichtung;

  const LeistungsnachweisTyp(this.name, this.gewichtung);

  static LeistungsnachweisTyp fromString(String name) {
    return LeistungsnachweisTyp.values.firstWhere(
      (t) => t.name == name,
      orElse: () => LeistungsnachweisTyp.sonstiges,
    );
  }
}

/// Leistungsnachweis (Prüfung, Test, mündliche Note, etc.)
class Leistungsnachweis {
  final String id;
  final String subjectId; // Fach
  final String klasseId; // Klasse
  final LeistungsnachweisTyp typ;
  final String bezeichnung; // z.B. "1. Schulaufgabe"
  final DateTime datum;
  final double maxPunkte; // Maximale Punktzahl (z.B. 100)
  final String? beschreibung;
  final DateTime createdAt;
  final DateTime updatedAt;

  Leistungsnachweis({
    required this.id,
    required this.subjectId,
    required this.klasseId,
    required this.typ,
    required this.bezeichnung,
    required this.datum,
    required this.maxPunkte,
    this.beschreibung,
    required this.createdAt,
    required this.updatedAt,
  });

  // Firestore Serialization
  factory Leistungsnachweis.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Leistungsnachweis(
      id: doc.id,
      subjectId: data['subjectId'] as String,
      klasseId: data['klasseId'] as String,
      typ: LeistungsnachweisTyp.fromString(data['typ'] as String),
      bezeichnung: data['bezeichnung'] as String,
      datum: (data['datum'] as Timestamp).toDate(),
      maxPunkte: (data['maxPunkte'] as num).toDouble(),
      beschreibung: data['beschreibung'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'klasseId': klasseId,
      'typ': typ.name,
      'bezeichnung': bezeichnung,
      'datum': Timestamp.fromDate(datum),
      'maxPunkte': maxPunkte,
      'beschreibung': beschreibung,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Leistungsnachweis copyWith({
    String? id,
    String? subjectId,
    String? klasseId,
    LeistungsnachweisTyp? typ,
    String? bezeichnung,
    DateTime? datum,
    double? maxPunkte,
    String? beschreibung,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Leistungsnachweis(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      klasseId: klasseId ?? this.klasseId,
      typ: typ ?? this.typ,
      bezeichnung: bezeichnung ?? this.bezeichnung,
      datum: datum ?? this.datum,
      maxPunkte: maxPunkte ?? this.maxPunkte,
      beschreibung: beschreibung ?? this.beschreibung,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// IHK Bayern Notenschlüssel
class IHKNotenschluessel {
  /// Konvertiert Prozent in IHK-Note
  /// 100-92% = 1, 91-81% = 2, 80-67% = 3, 66-50% = 4, 49-30% = 5, <30% = 6
  static int prozentZuNote(double prozent) {
    if (prozent >= 92) return 1;
    if (prozent >= 81) return 2;
    if (prozent >= 67) return 3;
    if (prozent >= 50) return 4;
    if (prozent >= 30) return 5;
    return 6;
  }

  /// Konvertiert erreichte Punkte in Note
  static int punkteZuNote(double erreichtePunkte, double maxPunkte) {
    if (maxPunkte <= 0) return 6;
    final prozent = (erreichtePunkte / maxPunkte) * 100;
    return prozentZuNote(prozent);
  }

  /// Gibt Notengrenzen als Map zurück
  static Map<int, String> get notengrenzen => {
    1: '92-100%',
    2: '81-91%',
    3: '67-80%',
    4: '50-66%',
    5: '30-49%',
    6: '0-29%',
  };
}
