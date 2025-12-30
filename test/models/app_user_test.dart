import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:induscore/models/app_user.dart';

void main() {
  group('UserRole', () {
    test('fromString liefert korrekten Wert', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('lehrer'), UserRole.lehrer);
      expect(UserRole.fromString('ausbilder'), UserRole.ausbilder);
      expect(UserRole.fromString('schueler'), UserRole.schueler);
    });

    test('fromString liefert lehrer als Fallback', () {
      expect(UserRole.fromString(null), UserRole.lehrer);
      expect(UserRole.fromString('unknown'), UserRole.lehrer);
      expect(UserRole.fromString(''), UserRole.lehrer);
    });

    test('label ist korrekt', () {
      expect(UserRole.admin.label, 'Admin');
      expect(UserRole.lehrer.label, 'Lehrer');
      expect(UserRole.ausbilder.label, 'Ausbilder');
      expect(UserRole.schueler.label, 'Schüler');
    });
  });

  group('UserStatus', () {
    test('fromString liefert korrekten Wert', () {
      expect(UserStatus.fromString('aktiv'), UserStatus.aktiv);
      expect(UserStatus.fromString('deaktiviert'), UserStatus.deaktiviert);
    });

    test('fromString liefert aktiv als Fallback', () {
      expect(UserStatus.fromString(null), UserStatus.aktiv);
      expect(UserStatus.fromString('unknown'), UserStatus.aktiv);
    });

    test('label ist korrekt', () {
      expect(UserStatus.aktiv.label, 'Aktiv');
      expect(UserStatus.deaktiviert.label, 'Deaktiviert');
    });
  });

  group('AppUser', () {
    late AppUser testUser;
    late DateTime testDate;

    setUp(() {
      testDate = DateTime(2025, 1, 15);
      testUser = AppUser(
        id: 'user1',
        email: 'test@example.com',
        name: 'Max Mustermann',
        kuerzel: 'mu',
        rolle: UserRole.lehrer,
        createdAt: testDate,
        favoriteKlassenIds: ['klasse1', 'klasse2'],
      );
    });

    test('kuerzel wird zu uppercase konvertiert', () {
      expect(testUser.kuerzel, 'MU');
    });

    test('isAdmin liefert korrekten Wert', () {
      expect(testUser.isAdmin, false);
      
      final admin = testUser.copyWith(rolle: UserRole.admin);
      expect(admin.isAdmin, true);
    });

    test('isAktiv liefert korrekten Wert', () {
      expect(testUser.isAktiv, true);
      
      final deaktiviert = testUser.copyWith(status: UserStatus.deaktiviert);
      expect(deaktiviert.isAktiv, false);
    });

    test('copyWith erstellt Kopie mit geänderten Werten', () {
      final copy = testUser.copyWith(
        name: 'Lisa Müller',
        kuerzel: 'lm',
        rolle: UserRole.admin,
      );

      expect(copy.name, 'Lisa Müller');
      expect(copy.kuerzel, 'LM');
      expect(copy.rolle, UserRole.admin);
      expect(copy.email, testUser.email); // Unverändert
      expect(copy.id, testUser.id); // Unverändert
    });

    test('copyWith mit allen Parametern', () {
      final lastLogin = DateTime(2025, 1, 20);
      final copy = testUser.copyWith(
        id: 'new-id',
        email: 'new@example.com',
        name: 'New Name',
        kuerzel: 'NN',
        rolle: UserRole.admin,
        status: UserStatus.deaktiviert,
        favoriteKlassenIds: ['klasse3'],
        createdAt: DateTime(2024, 1, 1),
        lastLoginAt: lastLogin,
      );

      expect(copy.id, 'new-id');
      expect(copy.email, 'new@example.com');
      expect(copy.name, 'New Name');
      expect(copy.kuerzel, 'NN');
      expect(copy.rolle, UserRole.admin);
      expect(copy.status, UserStatus.deaktiviert);
      expect(copy.favoriteKlassenIds, ['klasse3']);
      expect(copy.lastLoginAt, lastLogin);
    });

    test('toFirestore erstellt korrektes Map', () {
      final map = testUser.toFirestore();

      expect(map['email'], 'test@example.com');
      expect(map['name'], 'Max Mustermann');
      expect(map['kuerzel'], 'MU');
      expect(map['rolle'], 'lehrer');
      expect(map['status'], 'aktiv');
      expect(map['favoriteKlassenIds'], ['klasse1', 'klasse2']);
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['lastLoginAt'], isNull);
    });

    test('toFirestore mit lastLoginAt', () {
      final lastLogin = DateTime(2025, 1, 20);
      final userWithLogin = testUser.copyWith(lastLoginAt: lastLogin);
      final map = userWithLogin.toFirestore();

      expect(map['lastLoginAt'], isA<Timestamp>());
    });

    test('default status ist aktiv', () {
      final user = AppUser(
        id: 'new',
        email: 'new@example.com',
        name: 'New User',
        kuerzel: 'NU',
        rolle: UserRole.lehrer,
        createdAt: DateTime.now(),
      );

      expect(user.status, UserStatus.aktiv);
      expect(user.favoriteKlassenIds, isEmpty);
    });

    // Note: fromFirestore tests removed - DocumentSnapshot is sealed and cannot be mocked
  });
}
