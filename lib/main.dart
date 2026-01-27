// InduScore v0.23.0 - Phase 6 Documentation & Coverage
// Feature-based architecture with proper screen organization
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
// Feature imports - organized by domain
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/home_screen.dart';
import 'features/klassen/screens/klassen_screen.dart';
import 'features/klassen/screens/klassen_detail_screen.dart';
import 'features/faecher/screens/faecher_screen.dart';
import 'features/faecher/screens/faecher_detail_screen.dart';
import 'features/schueler/screens/schueler_screen.dart';
import 'features/schueler/screens/schueler_detail_screen.dart';
import 'features/leistungsnachweise/screens/leistungsnachweise_screen.dart';
import 'features/leistungsnachweise/screens/ln_editor_screen.dart';
import 'features/noten/screens/noten_eingabe_screen.dart';
import 'features/export/screens/noi_export_screen.dart';
import 'features/import/screens/csv_import_screen.dart';
import 'features/users/screens/user_verwaltung_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/admin/screens/feature_flags_screen.dart';
import 'core/theme/rbs_theme.dart';

/// Converts a [Stream] into a [Listenable] for use with GoRouter's refreshListenable.
/// This replaces the deprecated GoRouterRefreshStream from go_router < 10.0.
/// 
/// Usage:
/// ```dart
/// GoRouter(
///   refreshListenable: GoRouterRefreshStream(FirebaseAuth.instance.authStateChanges()),
///   // ...
/// )
/// ```
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Google Fonts konfigurieren - erlaubt Fallback auf Noto Sans für fehlende Zeichen
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Crashlytics initialisieren (nur in Release-Builds)
    if (!kDebugMode) {
      // Alle Flutter-Fehler an Crashlytics weiterleiten
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      
      // Async-Fehler abfangen (z.B. aus Futures, Streams)
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Run `flutterfire configure` to set up Firebase');
  }

  runApp(const ProviderScope(child: InduScoreApp()));
}

// Router configuration with auth redirect
// Using pageBuilder for lazy loading - widgets are only built when navigated to
final _router = GoRouter(
  initialLocation: '/login',
  refreshListenable: GoRouterRefreshStream(
    FirebaseAuth.instance.authStateChanges(),
  ),
  redirect: (context, state) {
    final isLoggedIn = FirebaseAuth.instance.currentUser != null;
    final loggingIn = state.fullPath == '/login';

    if (!isLoggedIn && !loggingIn) return '/login';
    if (isLoggedIn && loggingIn) return '/';
    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => const NoTransitionPage(child: LoginScreen()),
    ),
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => const NoTransitionPage(child: HomeScreen()),
    ),
    GoRoute(
      path: '/klassen',
      pageBuilder: (context, state) => const NoTransitionPage(child: KlassenScreen()),
    ),
    GoRoute(
      path: '/klassen/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: KlassenDetailScreen(klasseId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/faecher',
      pageBuilder: (context, state) => const NoTransitionPage(child: FaecherScreen()),
    ),
    GoRoute(
      path: '/faecher/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: FaecherDetailScreen(subjectId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/schueler',
      pageBuilder: (context, state) => const NoTransitionPage(child: SchuelerScreen()),
    ),
    GoRoute(
      path: '/schueler/:id',
      pageBuilder: (context, state) => NoTransitionPage(
        child: SchuelerDetailScreen(schuelerId: state.pathParameters['id']!),
      ),
    ),
    GoRoute(
      path: '/leistungsnachweise',
      pageBuilder: (context, state) => const NoTransitionPage(child: LeistungsnachweiseScreen()),
    ),
    GoRoute(
      path: '/leistungsnachweis/:id/edit',
      pageBuilder: (context, state) => NoTransitionPage(
        child: LNEditorScreen(leistungsnachweisId: state.pathParameters['id']!),
      ),
    ),
    // Noten-Übersicht Routen - Redirect zu Detail-Screens (v0.33.1: Navigation vereinheitlicht)
    GoRoute(
      path: '/noten/klasse/:klasseId',
      redirect: (context, state) => '/klassen/${state.pathParameters['klasseId']}',
    ),
    // v0.33.0: Redirect zu SchuelerDetailScreen (Navigation vereinheitlicht)
    GoRoute(
      path: '/noten/schueler/:studentId',
      redirect: (context, state) => '/schueler/${state.pathParameters['studentId']}',
    ),
    // Noten-Eingabe für einzelnen Leistungsnachweis
    GoRoute(
      path: '/noten/:leistungsnachweisId',
      pageBuilder: (context, state) => NoTransitionPage(
        child: NotenEingabeScreen(leistungsnachweisId: state.pathParameters['leistungsnachweisId']!),
      ),
    ),
    // NOI Export
    GoRoute(
      path: '/export',
      pageBuilder: (context, state) => const NoTransitionPage(child: NoiExportScreen()),
    ),
    // CSV Import
    GoRoute(
      path: '/import',
      pageBuilder: (context, state) => const NoTransitionPage(child: CsvImportScreen()),
    ),
    // Benutzerverwaltung (nur Admins)
    GoRoute(
      path: '/einstellungen/benutzer',
      pageBuilder: (context, state) => const NoTransitionPage(child: UserVerwaltungScreen()),
    ),
    // Admin Einstellungen (nur Admins) - Berufe & Fächer
    GoRoute(
      path: '/einstellungen',
      pageBuilder: (context, state) => const NoTransitionPage(child: SettingsScreen()),
    ),
    // Feature-Flags (nur Admins)
    GoRoute(
      path: '/einstellungen/feature-flags',
      pageBuilder: (context, state) => const NoTransitionPage(child: FeatureFlagsScreen()),
    ),
    // User-Profil (alle User-Rollen)
    GoRoute(
      path: '/profil',
      pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
    ),
  ],
);

class InduScoreApp extends StatelessWidget {
  const InduScoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'InduScore',
      debugShowCheckedModeBanner: false,
      theme: RBSTheme.lightTheme(), // RBS Styleguide Theme
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
