// InduScore v0.20.0 - Phase 3 Architecture Migration
// Feature-based architecture with proper screen organization
import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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
import 'features/noten/screens/noten_uebersicht_screen.dart';
import 'features/export/screens/noi_export_screen.dart';
import 'features/import/screens/csv_import_screen.dart';
import 'features/users/screens/user_verwaltung_screen.dart';
import 'features/settings/screens/settings_screen.dart';
import 'features/profile/screens/profile_screen.dart';
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
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Run `flutterfire configure` to set up Firebase');
  }

  runApp(const ProviderScope(child: InduScoreApp()));
}

// Router configuration with auth redirect
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
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/klassen',
      builder: (context, state) => const KlassenScreen(),
    ),
    GoRoute(
      path: '/klassen/:id',
      builder: (context, state) => KlassenDetailScreen(
        klasseId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/faecher',
      builder: (context, state) => const FaecherScreen(),
    ),
    GoRoute(
      path: '/faecher/:id',
      builder: (context, state) => FaecherDetailScreen(
        subjectId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/schueler',
      builder: (context, state) => const SchuelerScreen(),
    ),
    GoRoute(
      path: '/schueler/:id',
      builder: (context, state) => SchuelerDetailScreen(
        schuelerId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      path: '/leistungsnachweise',
      builder: (context, state) => const LeistungsnachweiseScreen(),
    ),
    GoRoute(
      path: '/leistungsnachweis/:id/edit',
      builder: (context, state) => LNEditorScreen(
        leistungsnachweisId: state.pathParameters['id']!,
      ),
    ),
    // Noten-Übersicht Routen (müssen vor /noten/:id stehen wegen Routing-Priorität)
    GoRoute(
      path: '/noten/klasse/:klasseId',
      builder: (context, state) => NotenUebersichtScreen(
        klasseId: state.pathParameters['klasseId']!,
      ),
    ),
    GoRoute(
      path: '/noten/fach/:fachId',
      builder: (context, state) => NotenUebersichtScreen(
        fachId: state.pathParameters['fachId']!,
      ),
    ),
    GoRoute(
      path: '/noten/schueler/:studentId',
      builder: (context, state) => NotenUebersichtScreen(
        studentId: state.pathParameters['studentId']!,
      ),
    ),
    // Noten-Eingabe für einzelnen Leistungsnachweis
    GoRoute(
      path: '/noten/:leistungsnachweisId',
      builder: (context, state) => NotenEingabeScreen(
        leistungsnachweisId: state.pathParameters['leistungsnachweisId']!,
      ),
    ),
    // NOI Export
    GoRoute(
      path: '/export',
      builder: (context, state) => const NoiExportScreen(),
    ),
    // CSV Import
    GoRoute(
      path: '/import',
      builder: (context, state) => const CsvImportScreen(),
    ),
    // Benutzerverwaltung (nur Admins)
    GoRoute(
      path: '/einstellungen/benutzer',
      builder: (context, state) => const UserVerwaltungScreen(),
    ),
    // Admin Einstellungen (nur Admins) - Berufe & Fächer
    GoRoute(
      path: '/einstellungen',
      builder: (context, state) => const SettingsScreen(),
    ),
    // User-Profil (alle User-Rollen)
    GoRoute(
      path: '/profil',
      builder: (context, state) => const ProfileScreen(),
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
