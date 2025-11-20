import 'package:cloud_firestore/cloud_firestore.dart';

enum GradeType {
  test, // Klassenarbeit
  oral, // Mündlich
  homework, // Hausaufgabe
  presentation, // Referat
  other, // Sonstiges
}

class Grade {
  final String id;
  final String studentId;
  final String subjectId;
  final double value; // 1.0 - 6.0 in Germany
  final GradeType type;
  final String? description;
  final double weight; // Gewichtung (z.B. 2.0 für Klassenarbeiten)
  final DateTime date;
  final DateTime createdAt;

  Grade({
    required this.id,
    required this.studentId,
    required this.subjectId,
    required this.value,
    required this.type,
    this.description,
    this.weight = 1.0,
    required this.date,
    required this.createdAt,
  });

  factory Grade.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Grade(
      id: doc.id,
      studentId: data['studentId'] as String,
      subjectId: data['subjectId'] as String,
      value: (data['value'] as num).toDouble(),
      type: GradeType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => GradeType.other,
      ),
      description: data['description'] as String?,
      weight: (data['weight'] as num?)?.toDouble() ?? 1.0,
      date: (data['date'] as Timestamp).toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'subjectId': subjectId,
      'value': value,
      'type': type.name,
      'description': description,
      'weight': weight,
      'date': Timestamp.fromDate(date),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Grade copyWith({
    String? id,
    String? studentId,
    String? subjectId,
    double? value,
    GradeType? type,
    String? description,
    double? weight,
    DateTime? date,
    DateTime? createdAt,
  }) {
    return Grade(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      subjectId: subjectId ?? this.subjectId,
      value: value ?? this.value,
      type: type ?? this.type,
      description: description ?? this.description,
      weight: weight ?? this.weight,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
