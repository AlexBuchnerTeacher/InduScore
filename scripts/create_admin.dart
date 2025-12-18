import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../lib/firebase_options.dart';
import '../lib/models/app_user.dart';

/// Script zum manuellen Anlegen eines Admin-Users
/// 
/// Usage: dart run scripts/create_admin.dart
void main() async {
  print('🚀 Admin-User wird angelegt...\n');

  // Firebase initialisieren
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final firestore = FirebaseFirestore.instance;

  // Admin-User erstellen
  final admin = AppUser(
    id: 'bu-admin', // Feste ID für den Admin
    email: 'alex.buchner@gmx.de',
    name: 'Alexander Buchner',
    kuerzel: 'BU',
    rolle: UserRole.admin,
    status: UserStatus.aktiv,
    favoriteKlassenIds: [],
    createdAt: DateTime.now(),
    lastLoginAt: null,
  );

  // In Firestore speichern
  await firestore.collection('users').doc(admin.id).set(admin.toFirestore());

  print('✅ Admin-User erfolgreich angelegt:');
  print('   ID:      ${admin.id}');
  print('   E-Mail:  ${admin.email}');
  print('   Name:    ${admin.name}');
  print('   Kürzel:  ${admin.kuerzel}');
  print('   Rolle:   ${admin.rolle.label}');
  print('\n⚠️  WICHTIG: Du musst noch einen Firebase Auth User mit dieser E-Mail erstellen!');
  print('   Firebase Console → Authentication → Add user');
  print('   E-Mail: alex.buchner@gmx.de');
  print('   Passwort: [selbst wählen]');
}
