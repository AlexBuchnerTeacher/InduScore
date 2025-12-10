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
/// Speichert Schülerdaten inkl. ASV-Felder.
/// ASV = Amtliche Schulverwaltung Bayern
class Student {
  final String id;
  final String firstName;
  final String lastName;
  final String klasseId;
  final DateTime eintrittsDatum;
  final DateTime? austrittsDatum;
  final StudentStatus status;
  final DateTime createdAt;
  
  // ASV-Felder (neu in v0.11.0)
  final String? asvId;              // Eindeutige ASV-ID für Sync
  final String? geschlecht;         // M / W
  final String? religion;           // RK, EV, IL, OR, etc.
  final String? email;              // Schüler-E-Mail
  final String? ausbildungsbetrieb; // Für spätere Ausbilder-Ansicht
  final bool befreiungDeutsch;      // Befreiung vom Deutschunterricht
  final bool befreiungPuG;          // Befreiung von Politik und Gesellschaft

  Student({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.klasseId,
    required this.eintrittsDatum,
    this.austrittsDatum,
    this.status = StudentStatus.aktiv,
    required this.createdAt,
    // ASV-Felder
    this.asvId,
    this.geschlecht,
    this.religion,
    this.email,
    this.ausbildungsbetrieb,
    this.befreiungDeutsch = false,
    this.befreiungPuG = false,
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
      // ASV-Felder
      asvId: data['asvId'] as String?,
      geschlecht: data['geschlecht'] as String?,
      religion: data['religion'] as String?,
      email: data['email'] as String?,
      ausbildungsbetrieb: data['ausbildungsbetrieb'] as String?,
      befreiungDeutsch: data['befreiungDeutsch'] as bool? ?? false,
      befreiungPuG: data['befreiungPuG'] as bool? ?? false,
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
      // ASV-Felder
      'asvId': asvId,
      'geschlecht': geschlecht,
      'religion': religion,
      'email': email,
      'ausbildungsbetrieb': ausbildungsbetrieb,
      'befreiungDeutsch': befreiungDeutsch,
      'befreiungPuG': befreiungPuG,
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
    // ASV-Felder
    String? asvId,
    String? geschlecht,
    String? religion,
    String? email,
    String? ausbildungsbetrieb,
    bool? befreiungDeutsch,
    bool? befreiungPuG,
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
      // ASV-Felder
      asvId: asvId ?? this.asvId,
      geschlecht: geschlecht ?? this.geschlecht,
      religion: religion ?? this.religion,
      email: email ?? this.email,
      ausbildungsbetrieb: ausbildungsbetrieb ?? this.ausbildungsbetrieb,
      befreiungDeutsch: befreiungDeutsch ?? this.befreiungDeutsch,
      befreiungPuG: befreiungPuG ?? this.befreiungPuG,
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
