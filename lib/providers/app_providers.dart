import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/student.dart';
import '../models/subject.dart';
import '../models/grade.dart';
import '../models/klasse.dart';
import '../models/leistungsnachweis.dart';
import '../models/beruf.dart';

// ============ APP INFO PROVIDERS ============

/// App Version aus pubspec.yaml (Single Source of Truth)
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

// ============ AUTH PROVIDERS ============

// AuthService singleton
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

// Current user stream
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current user (nullable)
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value;
});

// Is user logged in
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// ============ FIRESTORE PROVIDERS ============

// FirestoreService singleton
final firestoreServiceProvider = Provider<FirestoreService>(
  (ref) => FirestoreService(),
);

// ============ STUDENT PROVIDERS ============

// All students stream
final studentsProvider = StreamProvider<List<Student>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStudents();
});

// Student by ID
final studentProvider = FutureProvider.family<Student, String>((ref, id) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getStudent(id);
});

// Students by Klasse
final studentsByKlasseProvider = StreamProvider.family<List<Student>, String>((
  ref,
  klasseId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getStudentsByKlasse(klasseId);
});

// ============ SUBJECT PROVIDERS ============

// All subjects stream
final subjectsProvider = StreamProvider<List<Subject>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getSubjects();
});

// Subject by ID
final subjectProvider = FutureProvider.family<Subject, String>((ref, id) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getSubject(id);
});

// ============ GRADE PROVIDERS ============

// All grades stream
final gradesProvider = StreamProvider<List<Grade>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGrades();
});

// Grades by Leistungsnachweis
final gradesByLeistungsnachweisProvider =
    StreamProvider.family<List<Grade>, String>((ref, leistungsnachweisId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getGradesByLeistungsnachweis(leistungsnachweisId);
    });

// Grades by student
final gradesByStudentProvider = StreamProvider.family<List<Grade>, String>((
  ref,
  studentId,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getGradesByStudent(studentId);
});

// ============ KLASSEN PROVIDERS ============

// All Klassen stream
final klassenProvider = StreamProvider<List<Klasse>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getKlassen();
});

// Klasse by ID
final klasseProvider = FutureProvider.family<Klasse, String>((ref, id) async {
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getKlasse(id);
});

// Klassen by Schuljahr and Beruf
final klassenBySchuljahrAndBerufProvider =
    StreamProvider.family<List<Klasse>, ({String schuljahr, String berufCode})>(
      (ref, params) {
        final firestoreService = ref.watch(firestoreServiceProvider);
        return firestoreService.getKlassenBySchuljahrAndBeruf(
          params.schuljahr,
          params.berufCode,
        );
      },
    );

// Current Schuljahr provider
final currentSchuljahrProvider = Provider<Schuljahr>(
  (ref) => Schuljahr.current(),
);

// ============ LEISTUNGSNACHWEIS PROVIDERS ============

// All Leistungsnachweise stream
final leistungsnachweiseProvider = StreamProvider<List<Leistungsnachweis>>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getLeistungsnachweise();
});

// Leistungsnachweis by ID
final leistungsnachweisProvider =
    FutureProvider.family<Leistungsnachweis, String>((ref, id) async {
      final firestoreService = ref.read(firestoreServiceProvider);
      return firestoreService.getLeistungsnachweis(id);
    });

// Leistungsnachweise by Klasse
final leistungsnachweiseByKlasseProvider =
    StreamProvider.family<List<Leistungsnachweis>, String>((ref, klasseId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getLeistungsnachweiseByKlasse(klasseId);
    });

// Leistungsnachweise by Subject
final leistungsnachweiseBySubjectProvider =
    StreamProvider.family<List<Leistungsnachweis>, String>((ref, subjectId) {
      final firestoreService = ref.watch(firestoreServiceProvider);
      return firestoreService.getLeistungsnachweiseBySubject(subjectId);
    });
