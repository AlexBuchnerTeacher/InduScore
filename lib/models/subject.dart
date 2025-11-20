import 'package:cloud_firestore/cloud_firestore.dart';

class Subject {
  final String id;
  final String name;
  final String? shortName;
  final String? color; // Hex color string
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    this.shortName,
    this.color,
    required this.createdAt,
  });

  factory Subject.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Subject(
      id: doc.id,
      name: data['name'] as String,
      shortName: data['shortName'] as String?,
      color: data['color'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'shortName': shortName,
      'color': color,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Subject copyWith({
    String? id,
    String? name,
    String? shortName,
    String? color,
    DateTime? createdAt,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      shortName: shortName ?? this.shortName,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
