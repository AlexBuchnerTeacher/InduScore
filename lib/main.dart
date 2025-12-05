import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/klassen_screen.dart';
import 'screens/faecher_screen.dart';
import 'screens/schueler_screen.dart';
import 'screens/leistungsnachweise_screen.dart';
import 'screens/noten_eingabe_screen.dart';
import 'screens/noten_uebersicht_screen.dart';
import 'screens/noi_export_screen.dart';
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
      path: '/faecher',
      builder: (context, state) => const FaecherScreen(),
    ),
    GoRoute(
      path: '/schueler',
      builder: (context, state) => const SchuelerScreen(),
    ),
    GoRoute(
      path: '/leistungsnachweise',
      builder: (context, state) => const LeistungsnachweiseScreen(),
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
