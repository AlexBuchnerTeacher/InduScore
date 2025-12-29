import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/grade.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/klasse.dart';
import '../models/leistungsnachweis.dart';
import '../models/ln_exemption.dart';
import '../models/app_user.dart';
import '../models/schueler_unterricht.dart';

/// Ergebnis eines Schüler-Merge-Vorgangs
class MergeResult {
  final List<Student> matched; // Existierende Schüler die gematcht wurden
  final List<Student> added; // Neue Schüler die hinzugefügt wurden
  final List<Student>
  unmatched; // Existierende Schüler ohne Match (evtl. ausgetreten)

  MergeResult({
    required this.matched,
    required this.added,
    required this.unmatched,
  });

  bool get hasUnmatched => unmatched.isNotEmpty;
  bool get hasAdded => added.isNotEmpty;
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Collection references
  CollectionReference get _students => _db.collection('students');
  CollectionReference get _subjects => _db.collection('subjects');
  CollectionReference get _grades => _db.collection('grades');
  CollectionReference get _klassen => _db.collection('klassen');
  CollectionReference get _leistungsnachweise =>
      _db.collection('leistungsnachweise');

  // ============ STUDENTS ============

  Stream<List<Student>> getStudents() {
    return _students
        .orderBy('lastName')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList(),
        );
  }

  Future<Student> getStudent(String id) async {
    final doc = await _students.doc(id).get();
    if (!doc.exists) throw Exception('Student nicht gefunden');
    return Student.fromFirestore(doc);
  }

  Future<String> createStudent(Student student) async {
    final docRef = await _students.add(student.toFirestore());
    return docRef.id;
  }

  Future<void> updateStudent(Student student) async {
    await _students.doc(student.id).update(student.toFirestore());
  }

  Future<void> deleteStudent(String id) async {
    // Also delete all grades for this student
    final gradesSnapshot = await _grades
        .where('studentId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in gradesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_students.doc(id));
    await batch.commit();
  }

  /// Schüler nach Klasse abrufen (alphabetisch sortiert)
  Stream<List<Student>> getStudentsByKlasse(String klasseId) {
    return _students.where('klasseId', isEqualTo: klasseId).snapshots().map((
      snapshot,
    ) {
      final students = snapshot.docs
          .map((doc) => Student.fromFirestore(doc))
          .toList();
      students.sort((a, b) => a.sortKey.compareTo(b.sortKey));
      return students;
    });
  }

  // ============ SUBJECTS ============

  Stream<List<Subject>> getSubjects() {
    return _subjects
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList(),
        );
  }

  Future<Subject> getSubject(String id) async {
    final doc = await _subjects.doc(id).get();
    if (!doc.exists) throw Exception('Fach nicht gefunden');
    return Subject.fromFirestore(doc);
  }

  Future<String> createSubject(Subject subject) async {
    final docRef = await _subjects.add(subject.toFirestore());
    return docRef.id;
  }

  Future<void> updateSubject(Subject subject) async {
    await _subjects.doc(subject.id).update(subject.toFirestore());
  }

  Future<void> deleteSubject(String id) async {
    // Also delete all grades for this subject
    final gradesSnapshot = await _grades
        .where('subjectId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in gradesSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_subjects.doc(id));
    await batch.commit();
  }

  // ============ GRADES ============

  Stream<List<Grade>> getGrades() {
    return _grades
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList(),
        );
  }

  /// Noten für einen Leistungsnachweis abrufen
  Stream<List<Grade>> getGradesByLeistungsnachweis(String leistungsnachweisId) {
    return _grades
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Grade.fromFirestore(doc)).toList(),
        );
  }

  /// Alle Noten eines Schülers abrufen
  Stream<List<Grade>> getGradesByStudent(String studentId) {
    return _grades.where('studentId', isEqualTo: studentId).snapshots().map((
      snapshot,
    ) {
      final grades = snapshot.docs
          .map((doc) => Grade.fromFirestore(doc))
          .toList();
      grades.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return grades;
    });
  }

  Future<Grade> getGrade(String id) async {
    final doc = await _grades.doc(id).get();
    if (!doc.exists) throw Exception('Note nicht gefunden');
    return Grade.fromFirestore(doc);
  }

  Future<String> createGrade(Grade grade) async {
    final docRef = await _grades.add(grade.toFirestore());
    return docRef.id;
  }

  /// Mehrere Noten auf einmal speichern (Batch-Operation)
  Future<void> saveGrades(List<Grade> grades) async {
    if (grades.isEmpty) return;

    final batch = _db.batch();
    for (final grade in grades) {
      if (grade.id.isEmpty) {
        // Neue Note
        final docRef = _grades.doc();
        batch.set(docRef, grade.copyWith(id: docRef.id).toFirestore());
      } else {
        // Bestehende Note aktualisieren
        batch.update(_grades.doc(grade.id), grade.toFirestore());
      }
    }
    await batch.commit();
  }

  Future<void> updateGrade(Grade grade) async {
    await _grades.doc(grade.id).update(grade.toFirestore());
  }

  Future<void> deleteGrade(String id) async {
    await _grades.doc(id).delete();
  }

  /// Alle Noten eines Leistungsnachweises löschen
  Future<void> deleteGradesByLeistungsnachweis(
    String leistungsnachweisId,
  ) async {
    final snapshot = await _grades
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============ KLASSEN ============

  Stream<List<Klasse>> getKlassen() {
    return _klassen
        .orderBy('schuljahr', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Klasse.fromFirestore(doc)).toList(),
        );
  }

  Future<Klasse> getKlasse(String id) async {
    final doc = await _klassen.doc(id).get();
    if (!doc.exists) throw Exception('Klasse nicht gefunden');
    return Klasse.fromFirestore(doc);
  }

  Stream<List<Klasse>> getKlassenBySchuljahrAndBeruf(
    String schuljahr,
    String berufCode,
  ) {
    return _klassen
        .where('schuljahr', isEqualTo: schuljahr)
        .where('beruf', isEqualTo: berufCode)
        .snapshots()
        .map((snapshot) {
          final klassen = snapshot.docs
              .map((doc) => Klasse.fromFirestore(doc))
              .toList();
          klassen.sort((a, b) {
            final jahrCompare = a.jahrgangsstufe.compareTo(b.jahrgangsstufe);
            if (jahrCompare != 0) return jahrCompare;
            return a.zeitgruppe.nummer.compareTo(b.zeitgruppe.nummer);
          });
          return klassen;
        });
  }

  Future<String> createKlasse(Klasse klasse) async {
    final docRef = await _klassen.add(klasse.toFirestore());
    return docRef.id;
  }

  Future<void> updateKlasse(Klasse klasse) async {
    await _klassen.doc(klasse.id).update(klasse.toFirestore());
  }

  Future<void> deleteKlasse(String id) async {
    // Delete all related Leistungsnachweise
    final lnSnapshot = await _leistungsnachweise
        .where('klasseId', isEqualTo: id)
        .get();
    final batch = _db.batch();
    for (final doc in lnSnapshot.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_klassen.doc(id));
    await batch.commit();
  }

  // ============ LEISTUNGSNACHWEISE ============

  Stream<List<Leistungsnachweis>> getLeistungsnachweise() {
    return _leistungsnachweise
        .orderBy('datum', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Leistungsnachweis.fromFirestore(doc))
              .toList(),
        );
  }

  Future<Leistungsnachweis> getLeistungsnachweis(String id) async {
    final doc = await _leistungsnachweise.doc(id).get();
    if (!doc.exists) throw Exception('Leistungsnachweis nicht gefunden');
    return Leistungsnachweis.fromFirestore(doc);
  }

  Stream<List<Leistungsnachweis>> getLeistungsnachweiseByKlasse(
    String klasseId,
  ) {
    return _leistungsnachweise
        .where('klasseId', isEqualTo: klasseId)
        .snapshots()
        .map((snapshot) {
          final lns = snapshot.docs
              .map((doc) => Leistungsnachweis.fromFirestore(doc))
              .toList();
          lns.sort((a, b) => b.datum.compareTo(a.datum));
          return lns;
        });
  }

  Stream<List<Leistungsnachweis>> getLeistungsnachweiseBySubject(
    String subjectId,
  ) {
    return _leistungsnachweise
        .where('subjectId', isEqualTo: subjectId)
        .snapshots()
        .map((snapshot) {
          final lns = snapshot.docs
              .map((doc) => Leistungsnachweis.fromFirestore(doc))
              .toList();
          lns.sort((a, b) => b.datum.compareTo(a.datum));
          return lns;
        });
  }

  Future<String> createLeistungsnachweis(Leistungsnachweis ln) async {
    final docRef = await _leistungsnachweise.add(ln.toFirestore());
    return docRef.id;
  }

  Future<void> updateLeistungsnachweis(Leistungsnachweis ln) async {
    await _leistungsnachweise.doc(ln.id).update(ln.toFirestore());
  }

  Future<void> deleteLeistungsnachweis(String id) async {
    // Auch alle zugehörigen Noten löschen
    await deleteGradesByLeistungsnachweis(id);
    await _leistungsnachweise.doc(id).delete();
  }

  // ============ IMPORT (KLASSE + STUDENTS) ============

  /// Prüft ob eine Klasse mit gleichem Namen und Schuljahr bereits existiert
  Future<Klasse?> findExistingKlasse({
    required String berufCode,
    required int jahrgangsstufe,
    required int zeitgruppeNummer,
    required int laufendeNummer,
    required String schuljahr,
  }) async {
    final snapshot = await _klassen
        .where('beruf', isEqualTo: berufCode)
        .where('jahrgangsstufe', isEqualTo: jahrgangsstufe)
        .where('zeitgruppe', isEqualTo: zeitgruppeNummer)
        .where('laufendeNummer', isEqualTo: laufendeNummer)
        .where('schuljahr', isEqualTo: schuljahr)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return Klasse.fromFirestore(snapshot.docs.first);
  }

  /// Lädt alle Schüler einer Klasse als Liste (nicht Stream)
  Future<List<Student>> getStudentsByKlasseOnce(String klasseId) async {
    final snapshot = await _students
        .where('klasseId', isEqualTo: klasseId)
        .get();
    final students = snapshot.docs
        .map((doc) => Student.fromFirestore(doc))
        .toList();
    students.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return students;
  }

  /// Importiert eine neue Klasse mit Schülern (ohne Merge)
  Future<String> importKlasseMitSchuelern({
    required Klasse klasse,
    required List<Student> schueler,
    String importSource = 'pdf',
  }) async {
    final klasseId = klasse.id.isEmpty ? _klassen.doc().id : klasse.id;
    final klasseData = klasse.copyWith(id: klasseId).toFirestore()
      ..addAll({
        'importSource': importSource,
        'importTimestamp': Timestamp.now(),
      });

    final batch = _db.batch();
    batch.set(_klassen.doc(klasseId), klasseData);

    for (final student in schueler) {
      final studentId = student.id.isEmpty ? _students.doc().id : student.id;
      batch.set(
        _students.doc(studentId),
        student.copyWith(id: studentId, klasseId: klasseId).toFirestore(),
      );
    }

    await batch.commit();
    return klasseId;
  }

  /// Merged neue Schüler in eine existierende Klasse
  /// - Bestehende Schüler (nach Name gematcht) bleiben unverändert
  /// - Neue Schüler werden hinzugefügt
  /// - Rückgabe: Liste der nicht gematchten existierenden Schüler (zum Markieren als ausgetreten)
  Future<MergeResult> mergeStudentsIntoKlasse({
    required String klasseId,
    required List<Student> neueSchueler,
    required List<Student> existierendeSchueler,
    required Map<String, String> manuellesMatching, // neuerName -> existingId
  }) async {
    final matched = <Student>[];
    final added = <Student>[];
    final unmatched = <Student>[]; // Existierende ohne Match

    // Set für schnelles Lookup
    final matchedExistingIds = <String>{};

    final batch = _db.batch();

    for (final neuer in neueSchueler) {
      final neuerKey =
          '${neuer.firstName.toLowerCase()} ${neuer.lastName.toLowerCase()}';

      // 1. Manuelles Matching prüfen
      if (manuellesMatching.containsKey(neuerKey)) {
        final existingId = manuellesMatching[neuerKey]!;
        matchedExistingIds.add(existingId);
        matched.add(neuer);
        continue;
      }

      // 2. Automatisches Matching nach Name
      final existing = existierendeSchueler.firstWhere(
        (e) =>
            e.firstName.toLowerCase() == neuer.firstName.toLowerCase() &&
            e.lastName.toLowerCase() == neuer.lastName.toLowerCase(),
        orElse: () => Student(
          id: '',
          firstName: '',
          lastName: '',
          klasseId: '',
          eintrittsDatum: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );

      if (existing.id.isNotEmpty) {
        matchedExistingIds.add(existing.id);
        matched.add(neuer);
      } else {
        // Neuer Schüler - hinzufügen
        final studentId = _students.doc().id;
        batch.set(
          _students.doc(studentId),
          neuer.copyWith(id: studentId, klasseId: klasseId).toFirestore(),
        );
        added.add(neuer);
      }
    }

    // Nicht gematchte existierende Schüler finden
    for (final existing in existierendeSchueler) {
      if (!matchedExistingIds.contains(existing.id)) {
        unmatched.add(existing);
      }
    }

    await batch.commit();

    return MergeResult(matched: matched, added: added, unmatched: unmatched);
  }

  /// Markiert mehrere Schüler als ausgetreten
  Future<void> markStudentsAsAusgetreten(
    List<String> studentIds,
    DateTime austrittsDatum,
  ) async {
    final batch = _db.batch();
    for (final id in studentIds) {
      batch.update(_students.doc(id), {
        'status': StudentStatus.ausgetreten.name,
        'austrittsDatum': Timestamp.fromDate(austrittsDatum),
      });
    }
    await batch.commit();
  }

  // ============ STATISTICS ============

  /// Berechnet den gewichteten Notendurchschnitt
  /// Die Gewichtung kommt vom Leistungsnachweis-Typ (muss separat übergeben werden)
  double calculateSimpleAverage(List<Grade> grades) {
    if (grades.isEmpty) return 0.0;
    final sum = grades.fold<int>(0, (sum, g) => sum + g.note);
    return sum / grades.length;
  }

  /// Berechnet den gewichteten Durchschnitt für Noten mit Gewichtungen
  double calculateWeightedAverage(
    List<({Grade grade, double gewichtung})> gradesWithWeight,
  ) {
    if (gradesWithWeight.isEmpty) return 0.0;

    double totalWeighted = 0.0;
    double totalWeight = 0.0;

    for (final item in gradesWithWeight) {
      totalWeighted += item.grade.note * item.gewichtung;
      totalWeight += item.gewichtung;
    }

    return totalWeight > 0 ? totalWeighted / totalWeight : 0.0;
  }

  // ============ LN EXEMPTIONS (Befreiungen) ============

  CollectionReference get _lnExemptions => _db.collection('ln_exemptions');

  /// Alle LN-Befreiungen abrufen
  Stream<List<LnExemption>> getLnExemptions() {
    return _lnExemptions.snapshots().map(
      (snapshot) =>
          snapshot.docs.map((doc) => LnExemption.fromFirestore(doc)).toList(),
    );
  }

  /// Prüft ob ein Schüler von einem LN befreit ist
  Future<bool> isStudentExempt(
    String studentId,
    String leistungsnachweisId,
  ) async {
    final snapshot = await _lnExemptions
        .where('studentId', isEqualTo: studentId)
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Schüler als "nicht relevant" für LN markieren
  Future<String> createLnExemption({
    required String studentId,
    required String leistungsnachweisId,
    String? grund,
    String? createdBy,
  }) async {
    // Prüfen ob bereits vorhanden
    final existing = await _lnExemptions
        .where('studentId', isEqualTo: studentId)
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .get();

    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id; // Bereits vorhanden
    }

    final docRef = await _lnExemptions.add({
      'studentId': studentId,
      'leistungsnachweisId': leistungsnachweisId,
      'grund': grund,
      'createdAt': Timestamp.now(),
      'createdBy': createdBy,
    });
    return docRef.id;
  }

  /// Befreiung aufheben
  Future<void> deleteLnExemption(
    String studentId,
    String leistungsnachweisId,
  ) async {
    final snapshot = await _lnExemptions
        .where('studentId', isEqualTo: studentId)
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }

  /// Alle Befreiungen für einen LN abrufen
  Stream<List<LnExemption>> getLnExemptionsByLn(String leistungsnachweisId) {
    return _lnExemptions
        .where('leistungsnachweisId', isEqualTo: leistungsnachweisId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => LnExemption.fromFirestore(doc))
              .toList(),
        );
  }

  // ============ APP USERS ============

  CollectionReference get _appUsers => _db.collection('app_users');

  /// Alle App-Benutzer abrufen
  Stream<List<AppUser>> getAppUsers() {
    return _appUsers
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList(),
        );
  }

  /// Einzelnen Benutzer nach ID abrufen
  Future<AppUser?> getAppUser(String id) async {
    final doc = await _appUsers.doc(id).get();
    if (!doc.exists) return null;
    return AppUser.fromFirestore(doc);
  }

  /// Benutzer nach Email suchen
  Future<AppUser?> getAppUserByEmail(String email) async {
    final snapshot = await _appUsers
        .where('email', isEqualTo: email.toLowerCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return AppUser.fromFirestore(snapshot.docs.first);
  }

  /// Benutzer nach Kürzel suchen (für Login-Unterstützung)
  Future<AppUser> getAppUserByKuerzel(String kuerzel) async {
    final snapshot = await _appUsers
        .where('kuerzel', isEqualTo: kuerzel.toUpperCase())
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw Exception('Kein Benutzer mit Kürzel "$kuerzel" gefunden');
    }
    return AppUser.fromFirestore(snapshot.docs.first);
  }

  /// Neuen Benutzer erstellen
  Future<String> createAppUser(AppUser user) async {
    final docRef = await _appUsers.add(user.toFirestore());
    return docRef.id;
  }

  /// Benutzer mit spezifischer ID erstellen (z.B. Firebase Auth UID)
  Future<void> createAppUserWithId(String id, AppUser user) async {
    await _appUsers.doc(id).set(user.toFirestore());
  }

  /// Benutzer aktualisieren
  Future<void> updateAppUser(AppUser user) async {
    await _appUsers.doc(user.id).update(user.toFirestore());
  }

  /// Letzten Login aktualisieren
  Future<void> updateLastLogin(String userId) async {
    await _appUsers.doc(userId).update({'lastLoginAt': Timestamp.now()});
  }

  /// Benutzer deaktivieren
  Future<void> deactivateAppUser(String userId) async {
    await _appUsers.doc(userId).update({'status': UserStatus.deaktiviert.name});
  }

  /// Benutzer aktivieren
  Future<void> activateAppUser(String userId) async {
    await _appUsers.doc(userId).update({'status': UserStatus.aktiv.name});
  }

  /// Benutzer löschen
  Future<void> deleteAppUser(String userId) async {
    await _appUsers.doc(userId).delete();
  }

  /// Favoriten-Klassen für einen User aktualisieren
  Future<void> updateFavoriteKlassen(
    String userId,
    List<String> klassenIds,
  ) async {
    await _appUsers.doc(userId).update({'favoriteKlassenIds': klassenIds});
  }

  /// Prüft ob ein Kürzel bereits vergeben ist
  Future<bool> isKuerzelTaken(String kuerzel, {String? excludeUserId}) async {
    final snapshot = await _appUsers
        .where('kuerzel', isEqualTo: kuerzel.toUpperCase())
        .get();

    if (excludeUserId != null) {
      return snapshot.docs.any((doc) => doc.id != excludeUserId);
    }
    return snapshot.docs.isNotEmpty;
  }

  // ============ SCHUELER-UNTERRICHT (Beziehungen) ============

  CollectionReference get _schuelerUnterricht =>
      _db.collection('schueler_unterricht');

  /// Alle Unterrichts-Beziehungen abrufen
  Stream<List<SchuelerUnterricht>> getSchuelerUnterricht() {
    return _schuelerUnterricht.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => SchuelerUnterricht.fromFirestore(doc))
          .toList(),
    );
  }

  /// Unterricht nach Schüler
  Stream<List<SchuelerUnterricht>> getUnterrichtByStudent(String studentId) {
    return _schuelerUnterricht
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchuelerUnterricht.fromFirestore(doc))
              .toList(),
        );
  }

  /// Unterricht nach Lehrer
  Stream<List<SchuelerUnterricht>> getUnterrichtByLehrer(String lehrerId) {
    return _schuelerUnterricht
        .where('lehrerId', isEqualTo: lehrerId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => SchuelerUnterricht.fromFirestore(doc))
              .toList(),
        );
  }

  /// Neue Unterrichts-Beziehung erstellen
  Future<String> createSchuelerUnterricht(SchuelerUnterricht unterricht) async {
    final docRef = await _schuelerUnterricht.add(unterricht.toFirestore());
    return docRef.id;
  }

  /// Unterrichts-Beziehung löschen
  Future<void> deleteSchuelerUnterricht(String id) async {
    await _schuelerUnterricht.doc(id).delete();
  }

  /// Alle Beziehungen eines Schülers löschen
  Future<void> deleteUnterrichtByStudent(String studentId) async {
    final snapshot = await _schuelerUnterricht
        .where('studentId', isEqualTo: studentId)
        .get();
    final batch = _db.batch();
    for (final doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ============ ONCE-METHODEN (für Import) ============

  /// Alle Klassen einmalig abrufen (nicht als Stream)
  Future<List<Klasse>> getKlassenOnce() async {
    final snapshot = await _klassen.get();
    return snapshot.docs.map((doc) => Klasse.fromFirestore(doc)).toList();
  }

  /// Alle Fächer einmalig abrufen
  Future<List<Subject>> getSubjectsOnce() async {
    final snapshot = await _subjects.get();
    return snapshot.docs.map((doc) => Subject.fromFirestore(doc)).toList();
  }

  /// Alle AppUser einmalig abrufen
  Future<List<AppUser>> getAppUsersOnce() async {
    final snapshot = await _appUsers.get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  /// Alle Schüler einmalig abrufen
  Future<List<Student>> getStudentsOnce() async {
    final snapshot = await _students.get();
    return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
  }

  /// Alle Unterrichts-Beziehungen einmalig abrufen
  Future<List<SchuelerUnterricht>> getSchuelerUnterrichtOnce() async {
    final snapshot = await _schuelerUnterricht.get();
    return snapshot.docs
        .map((doc) => SchuelerUnterricht.fromFirestore(doc))
        .toList();
  }

  /// Schüler nach ASV-ID suchen
  Future<Student?> getStudentByAsvId(String asvId) async {
    final snapshot = await _students
        .where('asvId', isEqualTo: asvId)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Student.fromFirestore(snapshot.docs.first);
  }

  /// Fach nach Kürzel suchen
  Future<Subject?> getSubjectByKuerzel(String kuerzel) async {
    final snapshot = await _subjects
        .where('kuerzel', isEqualTo: kuerzel)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Subject.fromFirestore(snapshot.docs.first);
  }

  /// Klasse nach Name suchen
  Future<Klasse?> getKlasseByName(String name) async {
    final snapshot = await _klassen
        .where('name', isEqualTo: name)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return Klasse.fromFirestore(snapshot.docs.first);
  }
}
