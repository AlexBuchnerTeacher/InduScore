import 'package:cloud_firestore/cloud_firestore.dart';

/// Status eines Schülers
enum StudentStatus {
  aktiv('Aktiv'),
  ausgetreten('Ausgetreten');

  final String label;
  const StudentStatus(this.label);
  
  static StudentStatus fromString(String? value) {
    return StudentStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => StudentStatus.aktiv,
    );
  }
}

/// Schüler-Model
/// 
/// Speichert Vor- und Nachname in Firestore.
/// E2E-Verschlüsselung für sensible Daten kommt in v0.7.0.
class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String klasseId;
  final DateTime eintrittsDatum;
  final DateTime? austrittsDatum;
  final StudentStatus status;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.klasseId,
    required this.eintrittsDatum,
    this.austrittsDatum,
    this.status = StudentStatus.aktiv,
    required this.createdAt,
  });

  /// Anzeigename: "Vorname Nachname"
  String get displayName => '$firstName $lastName';
  
  /// Sortierkey: "Nachname, Vorname" (für alphabetische Sortierung)
  String get sortKey => '${lastName.toLowerCase()}, ${firstName.toLowerCase()}';
  
  /// Ist der Schüler aktiv?
  bool get isAktiv => status == StudentStatus.aktiv;

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      firstName: data['firstName'] as String? ?? '',
      lastName: data['lastName'] as String? ?? '',
      klasseId: data['klasseId'] as String? ?? '',
      eintrittsDatum: (data['eintrittsDatum'] as Timestamp?)?.toDate() ?? 
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      austrittsDatum: (data['austrittsDatum'] as Timestamp?)?.toDate(),
      status: StudentStatus.fromString(data['status'] as String?),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'klasseId': klasseId,
      'eintrittsDatum': Timestamp.fromDate(eintrittsDatum),
      'austrittsDatum': austrittsDatum != null 
          ? Timestamp.fromDate(austrittsDatum!) 
          : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Student copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? klasseId,
    DateTime? eintrittsDatum,
    DateTime? austrittsDatum,
    StudentStatus? status,
    DateTime? createdAt,
  }) {
    return Student(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      klasseId: klasseId ?? this.klasseId,
      eintrittsDatum: eintrittsDatum ?? this.eintrittsDatum,
      austrittsDatum: austrittsDatum ?? this.austrittsDatum,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Markiert den Schüler als ausgetreten
  Student markAsAusgetreten(DateTime datum) {
    return copyWith(
      status: StudentStatus.ausgetreten,
      austrittsDatum: datum,
    );
  }
}
