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
import '../models/ln_exemption.dart';
import '../models/app_user.dart';

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

// ============ ZEITGRUPPEN FILTER ============

/// Notifier für globalen Zeitgruppen-Filter
class ZeitgruppenFilterNotifier extends Notifier<int?> {
  @override
  int? build() => null; // Standardmäßig alle anzeigen
  
  void setFilter(int? zeitgruppe) => state = zeitgruppe;
  void clearFilter() => state = null;
}

/// Globaler Zeitgruppen-Filter (null = alle anzeigen)
final zeitgruppenFilterProvider = NotifierProvider<ZeitgruppenFilterNotifier, int?>(
  ZeitgruppenFilterNotifier.new,
);

/// Extrahiert die Zeitgruppe aus einem Klassennamen (vorletzte Ziffer)
int? extractZeitgruppe(String klassenName) {
  if (klassenName.length < 2) return null;
  final vorletzteZiffer = klassenName[klassenName.length - 2];
  return int.tryParse(vorletzteZiffer);
}

/// Gefilterte Klassen nach Zeitgruppe
final filteredKlassenProvider = Provider<List<Klasse>>((ref) {
  final klassen = ref.watch(klassenProvider).value ?? [];
  final zeitgruppe = ref.watch(zeitgruppenFilterProvider);
  
  if (zeitgruppe == null) return klassen;
  
  return klassen.where((k) => extractZeitgruppe(k.name) == zeitgruppe).toList();
});

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

// ============ LN EXEMPTIONS (Befreiungen) ============

/// Alle LN-Befreiungen
final lnExemptionsProvider = StreamProvider<List<LnExemption>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getLnExemptions();
});

// ============ NACHSCHREIBER PROVIDERS ============

/// Eskalationsstufe für Nachschreiber
enum NachschreiberStufe {
  stufe1, // ≤ 2 Tage alt (gelb)
  stufe2, // ≤ 2 Wochen alt (orange)
  stufe3, // > 2 Wochen alt (rot)
}

/// Ein Schüler, der einen LN nachschreiben muss
class Nachschreiber {
  final Student student;
  final Leistungsnachweis leistungsnachweis;
  final Klasse klasse;
  final Subject? subject;
  final NachschreiberStufe stufe;
  final int tageAlt;

  Nachschreiber({
    required this.student,
    required this.leistungsnachweis,
    required this.klasse,
    this.subject,
    required this.stufe,
    required this.tageAlt,
  });
}

/// Berechnet die Eskalationsstufe basierend auf dem LN-Datum
NachschreiberStufe _berechneStufe(DateTime lnDatum) {
  final tage = DateTime.now().difference(lnDatum).inDays;
  if (tage <= 2) return NachschreiberStufe.stufe1;
  if (tage <= 14) return NachschreiberStufe.stufe2;
  return NachschreiberStufe.stufe3;
}

/// Provider für alle Nachschreiber
/// 
/// Ein Schüler ist Nachschreiber wenn:
/// - Er aktiv in einer Klasse ist
/// - Die Klasse einen LN hat
/// - Mindestens ein anderer Schüler dieser Klasse hat eine Note für den LN
/// - Dieser Schüler hat KEINE Note für den LN
/// - Dieser Schüler ist NICHT von diesem LN befreit
final nachschreiberProvider = Provider<List<Nachschreiber>>((ref) {
  final students = ref.watch(studentsProvider).value ?? [];
  final leistungsnachweise = ref.watch(leistungsnachweiseProvider).value ?? [];
  final grades = ref.watch(gradesProvider).value ?? [];
  final klassen = ref.watch(klassenProvider).value ?? [];
  final subjects = ref.watch(subjectsProvider).value ?? [];
  final exemptions = ref.watch(lnExemptionsProvider).value ?? [];

  final nachschreiber = <Nachschreiber>[];

  // Erstelle Map für schnellen Zugriff
  final klassenMap = {for (final k in klassen) k.id: k};
  final subjectMap = {for (final s in subjects) s.id: s};
  
  // Erstelle Set für befreite Student-LN Kombinationen
  final exemptSet = <String>{};
  for (final e in exemptions) {
    exemptSet.add('${e.studentId}_${e.leistungsnachweisId}');
  }
  
  // Gruppiere Schüler nach Klasse (nur aktive Schüler)
  final studentsByKlasse = <String, List<Student>>{};
  for (final student in students.where((s) => s.status == StudentStatus.aktiv)) {
    studentsByKlasse.putIfAbsent(student.klasseId, () => []).add(student);
  }

  // Für jeden LN prüfen
  for (final ln in leistungsnachweise) {
    final klasseStudents = studentsByKlasse[ln.klasseId] ?? [];
    if (klasseStudents.isEmpty) continue;

    // Finde alle Noten für diesen LN
    final lnGrades = grades.where((g) => g.leistungsnachweisId == ln.id).toList();
    if (lnGrades.isEmpty) continue; // Noch keine Noten eingetragen -> kein Nachschreiber

    // Schüler mit Note für diesen LN
    final studentIdsWithGrade = lnGrades.map((g) => g.studentId).toSet();

    // Schüler ohne Note und ohne Befreiung = Nachschreiber
    for (final student in klasseStudents) {
      // Prüfe ob Schüler befreit ist
      final isExempt = exemptSet.contains('${student.id}_${ln.id}');
      if (isExempt) continue;
      
      if (!studentIdsWithGrade.contains(student.id)) {
        final klasse = klassenMap[ln.klasseId];
        if (klasse == null) continue;

        final tageAlt = DateTime.now().difference(ln.datum).inDays;
        nachschreiber.add(Nachschreiber(
          student: student,
          leistungsnachweis: ln,
          klasse: klasse,
          subject: subjectMap[ln.subjectId],
          stufe: _berechneStufe(ln.datum),
          tageAlt: tageAlt,
        ));
      }
    }
  }

  // Sortiere nach Stufe (kritischste zuerst) und dann nach Datum
  nachschreiber.sort((a, b) {
    final stufeCompare = b.stufe.index.compareTo(a.stufe.index);
    if (stufeCompare != 0) return stufeCompare;
    return b.tageAlt.compareTo(a.tageAlt);
  });

  return nachschreiber;
});

/// Gefilterte Nachschreiber nach Zeitgruppe
final filteredNachschreiberProvider = Provider<List<Nachschreiber>>((ref) {
  final nachschreiber = ref.watch(nachschreiberProvider);
  final zeitgruppe = ref.watch(zeitgruppenFilterProvider);
  
  if (zeitgruppe == null) return nachschreiber;
  
  return nachschreiber.where((n) => extractZeitgruppe(n.klasse.name) == zeitgruppe).toList();
});

// ============ APP USER PROVIDERS ============

/// Alle App-Benutzer
final appUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAppUsers();
});

/// Aktueller eingeloggter AppUser (mit Profildaten aus Firestore)
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider);
  if (firebaseUser == null) return null;
  
  final firestoreService = ref.read(firestoreServiceProvider);
  return firestoreService.getAppUserByEmail(firebaseUser.email ?? '');
});

/// Prüft ob der aktuelle Benutzer Admin ist
final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final appUser = ref.watch(currentAppUserProvider).value;
  return appUser?.isAdmin ?? false;
});
