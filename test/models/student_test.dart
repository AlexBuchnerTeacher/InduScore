import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:induscore/models/student.dart';

void main() {
  group('Student Model Tests', () {
    // Test Data
    final testDate = DateTime(2024, 1, 15, 10, 30);
    final austrittDate = DateTime(2024, 12, 31);

    final testData = {
      'firstName': 'Max',
      'lastName': 'Mustermann',
      'klasseId': 'EAT321',
      'eintrittsDatum': Timestamp.fromDate(testDate),
      'austrittsDatum': null,
      'status': 'aktiv',
      'createdAt': Timestamp.fromDate(testDate),
      'asvId': 'ASV12345',
      'geschlecht': 'M',
      'religion': 'RK',
      'email': 'max@example.com',
      'ausbildungsbetrieb': 'Musterfirma GmbH',
      'befreiungDeutsch': false,
      'befreiungPuG': true,
    };

    test('fromFirestore should correctly parse all fields', () {
      final mockDoc = _MockDocumentSnapshot('student1', testData);
      final student = Student.fromFirestore(mockDoc);

      expect(student.id, 'student1');
      expect(student.firstName, 'Max');
      expect(student.lastName, 'Mustermann');
      expect(student.klasseId, 'EAT321');
      expect(student.eintrittsDatum, testDate);
      expect(student.austrittsDatum, null);
      expect(student.status, StudentStatus.aktiv);
      expect(student.createdAt, testDate);
      expect(student.asvId, 'ASV12345');
      expect(student.geschlecht, 'M');
      expect(student.religion, 'RK');
      expect(student.email, 'max@example.com');
      expect(student.ausbildungsbetrieb, 'Musterfirma GmbH');
      expect(student.befreiungDeutsch, false);
      expect(student.befreiungPuG, true);
    });

    test('fromFirestore should handle missing optional fields', () {
      final minimalData = {
        'firstName': 'Anna',
        'lastName': 'Schmidt',
        'klasseId': 'EIT221',
        'createdAt': Timestamp.fromDate(testDate),
      };
      final mockDoc = _MockDocumentSnapshot('student2', minimalData);
      final student = Student.fromFirestore(mockDoc);

      expect(student.firstName, 'Anna');
      expect(student.lastName, 'Schmidt');
      expect(student.klasseId, 'EIT221');
      expect(student.eintrittsDatum, testDate); // Falls zu createdAt
      expect(student.austrittsDatum, null);
      expect(student.status, StudentStatus.aktiv); // Default
      expect(student.asvId, null);
      expect(student.geschlecht, null);
      expect(student.religion, null);
      expect(student.email, null);
      expect(student.ausbildungsbetrieb, null);
      expect(student.befreiungDeutsch, false); // Default
      expect(student.befreiungPuG, false); // Default
    });

    test('fromFirestore should handle ausgetreten status', () {
      final dataWithAustritt = {
        ...testData,
        'status': 'ausgetreten',
        'austrittsDatum': Timestamp.fromDate(austrittDate),
      };
      final mockDoc = _MockDocumentSnapshot('student3', dataWithAustritt);
      final student = Student.fromFirestore(mockDoc);

      expect(student.status, StudentStatus.ausgetreten);
      expect(student.austrittsDatum, austrittDate);
      expect(student.isAktiv, false);
    });

    test('toFirestore should correctly serialize all fields', () {
      final student = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        austrittsDatum: null,
        status: StudentStatus.aktiv,
        createdAt: testDate,
        asvId: 'ASV12345',
        geschlecht: 'M',
        religion: 'RK',
        email: 'max@example.com',
        ausbildungsbetrieb: 'Musterfirma GmbH',
        befreiungDeutsch: false,
        befreiungPuG: true,
      );

      final firestoreData = student.toFirestore();

      expect(firestoreData['firstName'], 'Max');
      expect(firestoreData['lastName'], 'Mustermann');
      expect(firestoreData['klasseId'], 'EAT321');
      expect((firestoreData['eintrittsDatum'] as Timestamp).toDate(), testDate);
      expect(firestoreData['austrittsDatum'], null);
      expect(firestoreData['status'], 'aktiv');
      expect((firestoreData['createdAt'] as Timestamp).toDate(), testDate);
      expect(firestoreData['asvId'], 'ASV12345');
      expect(firestoreData['geschlecht'], 'M');
      expect(firestoreData['religion'], 'RK');
      expect(firestoreData['email'], 'max@example.com');
      expect(firestoreData['ausbildungsbetrieb'], 'Musterfirma GmbH');
      expect(firestoreData['befreiungDeutsch'], false);
      expect(firestoreData['befreiungPuG'], true);
    });

    test('toFirestore should handle austrittsDatum when present', () {
      final student = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        austrittsDatum: austrittDate,
        status: StudentStatus.ausgetreten,
        createdAt: testDate,
      );

      final firestoreData = student.toFirestore();

      expect((firestoreData['austrittsDatum'] as Timestamp).toDate(), austrittDate);
      expect(firestoreData['status'], 'ausgetreten');
    });

    test('copyWith should update specified fields only', () {
      final original = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        status: StudentStatus.aktiv,
        createdAt: testDate,
        asvId: 'ASV12345',
      );

      final updated = original.copyWith(
        firstName: 'Maximilian',
        klasseId: 'EIT221',
        status: StudentStatus.ausgetreten,
        austrittsDatum: austrittDate,
      );

      // Updated fields
      expect(updated.firstName, 'Maximilian');
      expect(updated.klasseId, 'EIT221');
      expect(updated.status, StudentStatus.ausgetreten);
      expect(updated.austrittsDatum, austrittDate);

      // Unchanged fields
      expect(updated.id, 'student1');
      expect(updated.lastName, 'Mustermann');
      expect(updated.eintrittsDatum, testDate);
      expect(updated.createdAt, testDate);
      expect(updated.asvId, 'ASV12345');
    });

    test('displayName should return "firstName lastName"', () {
      final student = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        createdAt: testDate,
      );

      expect(student.displayName, 'Max Mustermann');
    });

    test('sortKey should return lowercase "lastName, firstName"', () {
      final student = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        createdAt: testDate,
      );

      expect(student.sortKey, 'mustermann, max');
    });

    test('isAktiv should return true for aktiv status', () {
      final student = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        status: StudentStatus.aktiv,
        createdAt: testDate,
      );

      expect(student.isAktiv, true);
    });

    test('isAktiv should return false for ausgetreten status', () {
      final student = Student(
        id: 'student1',
        firstName: 'Max',
        lastName: 'Mustermann',
        klasseId: 'EAT321',
        eintrittsDatum: testDate,
        status: StudentStatus.ausgetreten,
        austrittsDatum: austrittDate,
        createdAt: testDate,
      );

      expect(student.isAktiv, false);
    });

    test('StudentStatus.fromString should handle valid values', () {
      expect(StudentStatus.fromString('aktiv'), StudentStatus.aktiv);
      expect(StudentStatus.fromString('ausgetreten'), StudentStatus.ausgetreten);
    });

    test('StudentStatus.fromString should default to aktiv for invalid values', () {
      expect(StudentStatus.fromString('invalid'), StudentStatus.aktiv);
      expect(StudentStatus.fromString(null), StudentStatus.aktiv);
    });

    test('roundtrip fromFirestore/toFirestore should preserve data', () {
      final mockDoc = _MockDocumentSnapshot('student1', testData);
      final student = Student.fromFirestore(mockDoc);
      final firestoreData = student.toFirestore();

      // Verify all fields are preserved (excluding id which is not in toFirestore)
      expect(firestoreData['firstName'], testData['firstName']);
      expect(firestoreData['lastName'], testData['lastName']);
      expect(firestoreData['klasseId'], testData['klasseId']);
      expect(firestoreData['status'], testData['status']);
      expect(firestoreData['asvId'], testData['asvId']);
      expect(firestoreData['geschlecht'], testData['geschlecht']);
      expect(firestoreData['religion'], testData['religion']);
      expect(firestoreData['email'], testData['email']);
      expect(firestoreData['ausbildungsbetrieb'], testData['ausbildungsbetrieb']);
      expect(firestoreData['befreiungDeutsch'], testData['befreiungDeutsch']);
      expect(firestoreData['befreiungPuG'], testData['befreiungPuG']);
    });
  });
}

// Fake DocumentSnapshot for testing
class _FakeDocumentSnapshot implements DocumentSnapshot<Map<String, dynamic>> {
  @override
  final String id;

  final Map<String, dynamic> _data;

  _FakeDocumentSnapshot(this.id, this._data);

  @override
  Map<String, dynamic>? data() => _data;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
