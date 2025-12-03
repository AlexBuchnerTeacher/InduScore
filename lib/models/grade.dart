import 'package:cloud_firestore/cloud_firestore.dart';

/// Tendenz einer Note (optional, nur Info, keine Berechnung)
enum Tendenz {
  plus('+'),
  minus('-'),
  keine('');

  final String symbol;
  const Tendenz(this.symbol);

  static Tendenz fromString(String? value) {
    if (value == '+') return Tendenz.plus;
    if (value == '-') return Tendenz.minus;
    return Tendenz.keine;
  }
}

/// Note zu einem Leistungsnachweis
/// 
/// Eine Note gehört immer zu einem Schüler und einem Leistungsnachweis.
/// Die Gewichtung wird vom Leistungsnachweis abgeleitet.
class Grade {
  final String id;
  final String studentId;
  final String leistungsnachweisId;
  final int note; // 1-6
  final Tendenz tendenz; // +, - oder keine (nur Info, keine Berechnung)
  final String? kommentar;
  final DateTime createdAt;
  final DateTime updatedAt;

  Grade({
    required this.id,
    required this.studentId,
    required this.leistungsnachweisId,
    required this.note,
    this.tendenz = Tendenz.keine,
    this.kommentar,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Formatierte Note mit Tendenz (z.B. "2+", "3-", "1")
  String get noteFormatiert => '$note${tendenz.symbol}';

  factory Grade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Grade(
      id: doc.id,
      studentId: data['studentId'] as String,
      leistungsnachweisId: data['leistungsnachweisId'] as String,
      note: data['note'] as int,
      tendenz: Tendenz.fromString(data['tendenz'] as String?),
      kommentar: data['kommentar'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'leistungsnachweisId': leistungsnachweisId,
      'note': note,
      'tendenz': tendenz == Tendenz.keine ? null : tendenz.symbol,
      'kommentar': kommentar,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Grade copyWith({
    String? id,
    String? studentId,
    String? leistungsnachweisId,
    int? note,
    Tendenz? tendenz,
    String? kommentar,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Grade(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      leistungsnachweisId: leistungsnachweisId ?? this.leistungsnachweisId,
      note: note ?? this.note,
      tendenz: tendenz ?? this.tendenz,
      kommentar: kommentar ?? this.kommentar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Prüft, ob ein Kommentar vorhanden ist
  bool get hasKommentar => kommentar != null && kommentar!.isNotEmpty;
}
