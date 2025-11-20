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

  /// Vollständiger Name mit Schuljahr: "EAT321 (2024/25)"
  String get fullName => '$name ($schuljahr)';

  // Firestore Serialization
  factory Klasse.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Klasse(
      id: doc.id,
      beruf: Beruf.fromCode(data['beruf'] as String),
      jahrgangsstufe: data['jahrgangsstufe'] as int,
      zeitgruppe: Zeitgruppe.fromNummer(data['zeitgruppe'] as int),
      laufendeNummer: data['laufendeNummer'] as int,
      schuljahr: Schuljahr.fromString(data['schuljahr'] as String),
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
