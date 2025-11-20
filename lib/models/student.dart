import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String? className;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.className,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] as String,
      lastName: data['lastName'] as String,
      className: data['className'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'className': className,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? className,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      className: className ?? this.className,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
