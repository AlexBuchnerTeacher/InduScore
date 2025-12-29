import 'package:cloud_firestore/cloud_firestore.dart';

/// Benutzerrolle im System
/// 
/// Hinweis: 'ausbilder' und 'schueler' sind für eine separate App reserviert
/// und werden in dieser Anwendung aktuell nicht aktiv genutzt.
enum UserRole {
  admin('Admin'),
  lehrer('Lehrer'),
  ausbilder('Ausbilder'),      // Reserviert für separate App
  schueler('Schüler');         // Reserviert für separate App

  final String label;
  const UserRole(this.label);

  static UserRole fromString(String? value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.lehrer,
    );
  }
}

/// Benutzerstatus
enum UserStatus {
  aktiv('Aktiv'),
  deaktiviert('Deaktiviert');

  final String label;
  const UserStatus(this.label);

  static UserStatus fromString(String? value) {
    return UserStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => UserStatus.aktiv,
    );
  }
}

/// App-Benutzer (Lehrer/Admin)
/// 
/// Verwaltet Benutzerkonten für die Anwendung.
/// Schüler werden später als separate Entität hinzugefügt.
class AppUser {
  final String id;
  final String email;
  final String name; // Anzeigename (z.B. "Max Mustermann")
  final String kuerzel; // Fest vergeben (z.B. "MU")
  final UserRole rolle;
  final UserStatus status;
  final List<String> favoriteKlassenIds; // Favoriten-Klassen für Dashboard
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  AppUser({
    required this.id,
    required this.email,
    required this.name,
    required String kuerzel,
    required this.rolle,
    required this.createdAt, this.status = UserStatus.aktiv,
    this.favoriteKlassenIds = const [],
    this.lastLoginAt,
  }) : kuerzel = kuerzel.toUpperCase(); // Kürzel immer uppercase

  /// Erstellt AppUser aus Firestore-Dokument
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppUser(
      id: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
      kuerzel: (data['kuerzel'] as String? ?? '').toUpperCase(),
      rolle: UserRole.fromString(data['rolle'] as String?),
      status: UserStatus.fromString(data['status'] as String?),
      favoriteKlassenIds: (data['favoriteKlassenIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          // Migration: Alte klassenIds fallback
          (data['klassenIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Konvertiert zu Firestore-Map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'kuerzel': kuerzel,
      'rolle': rolle.name,
      'status': status.name,
      'favoriteKlassenIds': favoriteKlassenIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null 
          ? Timestamp.fromDate(lastLoginAt!) 
          : null,
    };
  }

  /// Kopie mit geänderten Werten
  AppUser copyWith({
    String? id,
    String? email,
    String? name,
    String? kuerzel,
    UserRole? rolle,
    UserStatus? status,
    List<String>? favoriteKlassenIds,
    DateTime? createdAt,
    DateTime? lastLoginAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      kuerzel: kuerzel ?? this.kuerzel,
      rolle: rolle ?? this.rolle,
      status: status ?? this.status,
      favoriteKlassenIds: favoriteKlassenIds ?? this.favoriteKlassenIds,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  /// Ist der Benutzer Admin?
  bool get isAdmin => rolle == UserRole.admin;

  /// Ist der Benutzer aktiv?
  bool get isAktiv => status == UserStatus.aktiv;
}
