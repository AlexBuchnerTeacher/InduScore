import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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
class ZeitgruppenFilterNotifier extends Notifier<Set<int>> {
  @override
  Set<int> build() => {}; // Standardmäßig leer = alle anzeigen
  
  void toggle(int zeitgruppe) {
    if (state.contains(zeitgruppe)) {
      state = {...state}..remove(zeitgruppe);
    } else {
      state = {...state, zeitgruppe};
    }
  }
  
  void setFilter(int? zeitgruppe) {
    if (zeitgruppe == null) {
      state = {};
    } else {
      state = {zeitgruppe};
    }
  }
  
  void clearFilter() => state = {};
}

/// Globaler Zeitgruppen-Filter (leer = alle anzeigen, Multi-Select möglich)
final zeitgruppenFilterProvider = NotifierProvider<ZeitgruppenFilterNotifier, Set<int>>(
  ZeitgruppenFilterNotifier.new,
);

/// Favoriten-Filter für Dashboard (nur favoriteKlassenIds anzeigen)
class FavoritenFilterNotifier extends Notifier<bool> {
  @override
  bool build() {
    // Default: Lehrer/Ausbilder sehen nur Favoriten, Admin sieht alle
    final currentUser = ref.watch(currentAppUserProvider).value;
    if (currentUser == null) return false;
    return currentUser.rolle == UserRole.lehrer || currentUser.rolle == UserRole.ausbilder;
  }
  
  void toggle() => state = !state;
  void setFilter(bool active) => state = active;
}

/// Favoriten-Filter Provider
final favoritenFilterProvider = NotifierProvider<FavoritenFilterNotifier, bool>(
  FavoritenFilterNotifier.new,
);

/// Extrahiert die Zeitgruppe aus einem Klassennamen (vorletzte Ziffer)
int? extractZeitgruppe(String klassenName) {
  if (klassenName.length < 2) return null;
  final vorletzteZiffer = klassenName[klassenName.length - 2];
  return int.tryParse(vorletzteZiffer);
}

/// Gefilterte Klassen nach Zeitgruppe UND Favoriten
final filteredKlassenProvider = Provider<List<Klasse>>((ref) {
  final klassen = ref.watch(klassenProvider).value ?? [];
  final zeitgruppen = ref.watch(zeitgruppenFilterProvider);
  final favoritenFilter = ref.watch(favoritenFilterProvider);
  final currentUser = ref.watch(currentAppUserProvider).value;
  
  // Schritt 1: Nach Favoriten filtern (wenn aktiv)
  var filtered = klassen;
  if (favoritenFilter && currentUser != null && currentUser.favoriteKlassenIds.isNotEmpty) {
    filtered = filtered.where((k) => currentUser.favoriteKlassenIds.contains(k.id)).toList();
  }
  
  // Schritt 2: Nach Zeitgruppe filtern (wenn aktiv)
  if (zeitgruppen.isEmpty) return filtered;
  
  return filtered.where((k) {
    final zg = extractZeitgruppe(k.name);
    return zg != null && zeitgruppen.contains(zg);
  }).toList();
});

/// Gefilterte Leistungsnachweise nach Zeitgruppe (über Klasse)
final filteredLeistungsnachweiseProvider = Provider<List<Leistungsnachweis>>((ref) {
  final allLN = ref.watch(leistungsnachweiseProvider).value ?? [];
  final zeitgruppen = ref.watch(zeitgruppenFilterProvider);
  
  if (zeitgruppen.isEmpty) return allLN;
  
  final klassen = ref.watch(klassenProvider).value ?? [];
  final klassenInZG = klassen
      .where((k) {
        final zg = extractZeitgruppe(k.name);
        return zg != null && zeitgruppen.contains(zg);
      })
      .map((k) => k.id)
      .toSet();
  
  return allLN.where((ln) => klassenInZG.contains(ln.klasseId)).toList();
});

// ============ LEISTUNGSNACHWEIS PROVIDERS ============

// All Leistungsnachweise stream
final leistungsnachweiseProvider = StreamProvider<List<Leistungsnachweis>>((
  ref,
) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getLeistungsnachweise();
});

// ============ OPTIMIZED LOOKUP PROVIDERS ============
// Pre-computed maps for O(1) lookups - prevents repeated list iterations
// Use these instead of .firstWhere() in widgets for better performance

/// Map of all Klassen by ID for O(1) lookup
final klassenMapProvider = Provider<Map<String, Klasse>>((ref) {
  final klassen = ref.watch(klassenProvider).value ?? [];
  return {for (final k in klassen) k.id: k};
});

/// Map of all Subjects by ID for O(1) lookup
final subjectsMapProvider = Provider<Map<String, Subject>>((ref) {
  final subjects = ref.watch(subjectsProvider).value ?? [];
  return {for (final s in subjects) s.id: s};
});

/// Map of all Students by ID for O(1) lookup
final studentsMapProvider = Provider<Map<String, Student>>((ref) {
  final students = ref.watch(studentsProvider).value ?? [];
  return {for (final s in students) s.id: s};
});

/// Map of all Leistungsnachweise by ID for O(1) lookup
final leistungsnachweiseMapProvider = Provider<Map<String, Leistungsnachweis>>((ref) {
  final lnList = ref.watch(leistungsnachweiseProvider).value ?? [];
  return {for (final ln in lnList) ln.id: ln};
});

// ============ DASHBOARD STATISTICS PROVIDER ============
// Computed provider for dashboard statistics - avoids unnecessary rebuilds
// by only providing counts instead of full lists

/// Dashboard statistics for efficient rendering
class DashboardStats {
  final int klassenCount;
  final int studentsCount;
  final int subjectsCount;
  final int gradesCount;
  final bool isLoading;

  const DashboardStats({
    required this.klassenCount,
    required this.studentsCount,
    required this.subjectsCount,
    required this.gradesCount,
    this.isLoading = false,
  });

  static const loading = DashboardStats(
    klassenCount: 0,
    studentsCount: 0,
    subjectsCount: 0,
    gradesCount: 0,
    isLoading: true,
  );
}

/// Provides dashboard statistics as computed values
/// Using .select() pattern internally - widget rebuilds only when counts change
final dashboardStatsProvider = Provider<DashboardStats>((ref) {
  final klassenAsync = ref.watch(klassenProvider);
  final studentsAsync = ref.watch(studentsProvider);
  final subjectsAsync = ref.watch(subjectsProvider);
  final gradesAsync = ref.watch(gradesProvider);

  // Check if any is loading
  if (klassenAsync.isLoading || studentsAsync.isLoading || 
      subjectsAsync.isLoading || gradesAsync.isLoading) {
    return DashboardStats.loading;
  }

  return DashboardStats(
    klassenCount: klassenAsync.value?.length ?? 0,
    studentsCount: studentsAsync.value?.length ?? 0,
    subjectsCount: subjectsAsync.value?.length ?? 0,
    gradesCount: gradesAsync.value?.length ?? 0,
  );
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
    required this.stufe, required this.tageAlt, this.subject,
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
  final zeitgruppen = ref.watch(zeitgruppenFilterProvider);
  
  if (zeitgruppen.isEmpty) return nachschreiber;
  
  return nachschreiber.where((n) {
    final zg = extractZeitgruppe(n.klasse.name);
    return zg != null && zeitgruppen.contains(zg);
  }).toList();
});

// ============ APP USER PROVIDERS ============

/// Alle App-Benutzer
final appUsersProvider = StreamProvider<List<AppUser>>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return firestoreService.getAppUsers();
});

/// Aktueller eingeloggter AppUser (mit Profildaten aus Firestore)
/// Erstellt automatisch einen AppUser beim ersten Login
final currentAppUserProvider = FutureProvider<AppUser?>((ref) async {
  final firebaseUser = ref.watch(currentUserProvider);
  if (firebaseUser == null) return null;
  
  final firestoreService = ref.read(firestoreServiceProvider);
  
  // Versuche AppUser aus Firestore zu laden
  final appUser = await firestoreService.getAppUserByEmail(firebaseUser.email ?? '');
  
  // Wenn kein AppUser existiert, erstelle einen (First-Run Setup)
  if (appUser == null) {
    final allUsers = await ref.read(appUsersProvider.future);
    
    // Erster User wird automatisch Admin
    final isFirstUser = allUsers.isEmpty;
    
    final newAppUser = AppUser(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      name: firebaseUser.displayName ?? firebaseUser.email ?? 'Unbekannt',
      kuerzel: _extractKuerzelFromEmail(firebaseUser.email ?? ''),
      rolle: isFirstUser ? UserRole.admin : UserRole.lehrer,
      status: UserStatus.aktiv,
      favoriteKlassenIds: [],
      createdAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );
    
    // In Firestore speichern
    await firestoreService.createAppUserWithId(firebaseUser.uid, newAppUser);
    
    return newAppUser;
  }
  
  // Letzten Login aktualisieren
  await firestoreService.updateLastLogin(appUser.id);
  
  return appUser;
});

/// Zentraler Provider für das Kürzel des aktuellen Benutzers
/// 
/// Verwendet das kuerzel-Feld aus dem AppUser-Profil.
/// Fallback auf E-Mail-Extraktion, falls kein Kürzel gesetzt ist oder bei Fehler.
/// 
/// WICHTIG: Dies ist ein FutureProvider, der auf die AppUser-Daten wartet.
/// Der Provider wird automatisch invalidiert wenn:
/// - Der Benutzer sich ein-/ausloggt (authStateProvider ändert sich)
/// - Das AppUser-Profil aktualisiert wird (currentAppUserProvider ändert sich)
final currentUserKuerzelProvider = FutureProvider<String>((ref) async {
  // Debug-Logging für bessere Nachverfolgung
  debugPrint('[currentUserKuerzelProvider] Resolving kuerzel...');
  
  try {
    // Warte auf AppUser-Daten (throws wenn Fehler, wartet wenn loading)
    final appUser = await ref.watch(currentAppUserProvider.future);
    
    // Primär: Kürzel aus AppUser (wenn nicht leer und nicht null)
    if (appUser != null && appUser.kuerzel.isNotEmpty) {
      debugPrint('[currentUserKuerzelProvider] Using AppUser.kuerzel: ${appUser.kuerzel}');
      return appUser.kuerzel;
    }
    
    // Fallback: Aus E-Mail extrahieren (wenn AppUser.kuerzel leer ist oder appUser null)
    debugPrint('[currentUserKuerzelProvider] AppUser.kuerzel is empty or null, using fallback...');
    return _getFallbackKuerzel(ref);
  } catch (error) {
    // Bei Fehler beim Laden des AppUser: Fallback verwenden
    debugPrint('[currentUserKuerzelProvider] Error loading AppUser: $error, using fallback...');
    // Check if ref is still mounted before using it
    if (!ref.mounted) {
      debugPrint('[currentUserKuerzelProvider] Ref disposed, cannot get fallback');
      return '??';
    }
    return _getFallbackKuerzel(ref);
  }
});

/// Helper: Fallback-Kürzel aus Firebase User E-Mail extrahieren
String _getFallbackKuerzel(Ref ref) {
  // Safety check in case ref was disposed
  if (!ref.mounted) {
    debugPrint('[_getFallbackKuerzel] Ref disposed, returning ??');
    return '??';
  }
  
  final firebaseUser = ref.watch(currentUserProvider);
  if (firebaseUser?.email != null) {
    final kuerzel = _extractKuerzelFromEmail(firebaseUser!.email!);
    debugPrint('[currentUserKuerzelProvider] Fallback kuerzel from email: $kuerzel');
    return kuerzel;
  }
  debugPrint('[currentUserKuerzelProvider] No Firebase user, returning ??');
  return '??';
}

/// Extrahiert Kürzel aus E-Mail (z.B. "MU" aus "mu@induscore.de")
String _extractKuerzelFromEmail(String email) {
  if (email.isEmpty) return 'XX';
  final parts = email.split('@');
  if (parts.isEmpty) return 'XX';
  final username = parts[0].toUpperCase();
  return username.length <= 4 ? username : username.substring(0, 4);
}

/// Prüft ob der aktuelle Benutzer Admin ist
/// Fallback: Wenn keine AppUsers existieren, ist der erste Firebase-Auth-User automatisch Admin
final isCurrentUserAdminProvider = Provider<bool>((ref) {
  final firebaseUser = ref.watch(currentUserProvider);
  
  // Nicht eingeloggt = kein Admin
  if (firebaseUser == null) {
    return false;
  }
  
  // AppUser-Daten aus Firestore laden
  final appUserAsync = ref.watch(currentAppUserProvider);
  final allUsersAsync = ref.watch(appUsersProvider);
  
  // Wenn AppUser existiert, dessen Rolle verwenden
  if (appUserAsync.hasValue && appUserAsync.value != null) {
    return appUserAsync.value!.isAdmin;
  }
  
  // Fallback für First-Run: Wenn Firebase Auth User existiert, 
  // aber noch keine AppUsers in Firestore angelegt sind,
  // ist der erste User automatisch Admin
  if (allUsersAsync.hasValue) {
    final allUsers = allUsersAsync.value ?? [];
    if (allUsers.isEmpty) {
      return true; // Erster User = Admin
    }
  }
  
  // Während Daten laden: Zugriff verweigern (sicherer Default)
  return false;
});
