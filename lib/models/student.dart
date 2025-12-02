import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

/// Schüler-Model mit DSGVO-konformer Pseudonymisierung
/// 
/// Speichert nur pseudonymisierte Daten in Firestore.
/// Das Mapping (Pseudonym → echter Name) wird lokal exportiert.
class Student {
  final String id;
  final String pseudonym; // z.B. "S001", "S002"
  final String? firstName; // Optional, nur lokal
  final String? lastName;  // Optional, nur lokal  
  final String klasseId;   // Referenz zur Klasse
  final DateTime createdAt;

  Student({
    required this.id,
    required this.pseudonym,
    this.firstName,
    this.lastName,
    required this.klasseId,
    required this.createdAt,
  });

  /// Anzeigename: Pseudonym oder echter Name falls vorhanden
  String get displayName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return pseudonym;
  }

  /// Generiert ein neues Pseudonym (S001, S002, ...)
  static String generatePseudonym(int index) {
    return 'S${(index + 1).toString().padLeft(3, '0')}';
  }

  /// Generiert ein zufälliges Pseudonym
  static String generateRandomPseudonym() {
    final random = Random();
    final number = random.nextInt(9999) + 1;
    return 'S${number.toString().padLeft(4, '0')}';
  }

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      pseudonym: data['pseudonym'] as String? ?? doc.id.substring(0, 6),
      firstName: data['firstName'] as String?,
      lastName: data['lastName'] as String?,
      klasseId: data['klasseId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Nur pseudonymisierte Daten werden in Firestore gespeichert
  Map<String, dynamic> toFirestore() {
    return {
      'pseudonym': pseudonym,
      'klasseId': klasseId,
      'createdAt': Timestamp.fromDate(createdAt),
      // firstName und lastName werden NICHT gespeichert (DSGVO)
    };
  }

  /// Für lokales Mapping-Export (CSV)
  Map<String, dynamic> toLocalMapping() {
    return {
      'pseudonym': pseudonym,
      'firstName': firstName ?? '',
      'lastName': lastName ?? '',
      'klasseId': klasseId,
    };
  }

  Student copyWith({
    String? id,
    String? pseudonym,
    String? firstName,
    String? lastName,
    String? klasseId,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      pseudonym: pseudonym ?? this.pseudonym,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      klasseId: klasseId ?? this.klasseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
