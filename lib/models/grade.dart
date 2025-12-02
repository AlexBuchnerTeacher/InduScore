import 'package:cloud_firestore/cloud_firestore.dart';

/// Note zu einem Leistungsnachweis
/// 
/// Eine Note gehört immer zu einem Schüler und einem Leistungsnachweis.
/// Die Gewichtung wird vom Leistungsnachweis-Typ abgeleitet.
class Grade {
  final String id;
  final String studentId;
  final String leistungsnachweisId; // Zuordnung zum Leistungsnachweis
  final double? punkte; // Erreichte Punkte (optional, für IHK-Schlüssel)
  final int note; // 1-6 (kann direkt eingegeben oder aus Punkten berechnet werden)
  final String? kommentar; // Tooltip-Kommentar für die Note
  final DateTime createdAt;
  final DateTime updatedAt;

  Grade({
    required this.id,
    required this.studentId,
    required this.leistungsnachweisId,
    this.punkte,
    required this.note,
    this.kommentar,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Grade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Grade(
      id: doc.id,
      studentId: data['studentId'] as String,
      leistungsnachweisId: data['leistungsnachweisId'] as String,
      punkte: (data['punkte'] as num?)?.toDouble(),
      note: data['note'] as int,
      kommentar: data['kommentar'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'leistungsnachweisId': leistungsnachweisId,
      'punkte': punkte,
      'note': note,
      'kommentar': kommentar,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Grade copyWith({
    String? id,
    String? studentId,
    String? leistungsnachweisId,
    double? punkte,
    int? note,
    String? kommentar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Grade(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      leistungsnachweisId: leistungsnachweisId ?? this.leistungsnachweisId,
      punkte: punkte ?? this.punkte,
      note: note ?? this.note,
      kommentar: kommentar ?? this.kommentar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Prüft, ob ein Kommentar vorhanden ist
  bool get hasKommentar => kommentar != null && kommentar!.isNotEmpty;
}
