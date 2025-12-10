import 'package:cloud_firestore/cloud_firestore.dart';

/// Schüler-Unterricht Beziehung
/// 
/// Speichert welcher Schüler welches Fach bei welchem Lehrer hat.
/// Wird beim ASV-Import automatisch angelegt.
/// 
/// Beispiel aus ASV:
/// "FU-IT_1/EAT411*1 IT-Systeme Schmidt"
/// → studentId: [Schüler-ID]
/// → subjectId: [IT-Fach-ID]
/// → lehrerId: [Schmidt-AppUser-ID]
/// → gruppe: "IT_1"
class SchuelerUnterricht {
  final String id;
  final String studentId;
  final String subjectId;
  final String lehrerId;      // AppUser-ID des Lehrers
  final String? gruppe;       // z.B. "IT_1", "AUT_2", "E_1"
  final String? klasseId;     // Optional: Klassen-Referenz
  final DateTime createdAt;

  SchuelerUnterricht({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.lehrerId,
    this.gruppe,
    this.klasseId,
    required this.createdAt,
  });

  factory SchuelerUnterricht.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchuelerUnterricht(
      id: doc.id,
      studentId: data['studentId'] as String,
      subjectId: data['subjectId'] as String,
      lehrerId: data['lehrerId'] as String,
      gruppe: data['gruppe'] as String?,
      klasseId: data['klasseId'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'lehrerId': lehrerId,
      'gruppe': gruppe,
      'klasseId': klasseId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Eindeutiger Schlüssel für Duplikat-Prüfung
  /// Format: studentId_subjectId_lehrerId_gruppe
  String get uniqueKey => '${studentId}_${subjectId}_${lehrerId}_${gruppe ?? ''}';

  SchuelerUnterricht copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    String? lehrerId,
    String? gruppe,
    String? klasseId,
    DateTime? createdAt,
  }) {
    return SchuelerUnterricht(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      lehrerId: lehrerId ?? this.lehrerId,
      gruppe: gruppe ?? this.gruppe,
      klasseId: klasseId ?? this.klasseId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
