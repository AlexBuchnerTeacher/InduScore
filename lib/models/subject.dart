import 'package:cloud_firestore/cloud_firestore.dart';
import 'beruf.dart';

/// Typ des Fachs fÃ¼r die Berufsschule
enum FachTyp {
  allgemein('Allgemeinbildend', 'ABF'), // Deutsch, Sozialkunde, etc.
  beruflich('Beruflich', 'BF'), // Fachspezifische Module
  lernfeld('Lernfeld', 'LF'); // Lernfelder 1-13

  final String name;
  final String code;

  const FachTyp(this.name, this.code);
}

class Subject {
  final String id;
  final String name;
  final String? shortName;
  final FachTyp typ;
  final List<Beruf> berufe; // Welche Berufe haben dieses Fach
  final int wochenstunden; // Wochenstunden pro Woche
  final double credits; // ECTS-Ã¤hnlich, z.B. 3.0
  final String? color; // Hex color string
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.typ, required this.berufe, required this.createdAt, this.shortName,
    this.wochenstunden = 2,
    this.credits = 3.0,
    this.color,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'] as String,
      shortName: data['shortName'] as String?,
      typ: FachTyp.values.firstWhere(
        (t) => t.code == data['typ'],
        orElse: () => FachTyp.beruflich,
      ),
      berufe:
          (data['berufe'] as List<dynamic>?)
              ?.map((b) => Beruf.fromCode(b as String))
              .toList() ??
          [],
      wochenstunden: data['wochenstunden'] as int? ?? 2,
      credits: (data['credits'] as num?)?.toDouble() ?? 3.0,
      color: data['color'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'shortName': shortName,
      'typ': typ.code,
      'berufe': berufe.map((b) => b.code).toList(),
      'wochenstunden': wochenstunden,
      'credits': credits,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Subject copyWith({
    String? id,
    String? name,
    String? shortName,
    FachTyp? typ,
    List<Beruf>? berufe,
    int? wochenstunden,
    double? credits,
    String? color,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      typ: typ ?? this.typ,
      berufe: berufe ?? this.berufe,
      wochenstunden: wochenstunden ?? this.wochenstunden,
      credits: credits ?? this.credits,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
