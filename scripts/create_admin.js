// Firebase Admin SDK - Admin User erstellen
const admin = require('firebase-admin');

// Service Account Key wird aus Firebase Console geladen
// Firebase Console → Project Settings → Service Accounts → Generate new private key
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

async function createAdmin() {
  console.log('🚀 Admin-User wird erstellt...\n');

  const email = 'alexander.buchner@bs-ie.muenchen.musin.de';
  const password = 'IndusCore2025!';
  let uid;

  try {
    // 1. Firebase Auth User erstellen
    console.log('Erstelle Firebase Auth User...');
    try {
      const userRecord = await auth.createUser({
        email: email,
        password: password,
        displayName: 'Alexander Buchner'
      });
      uid = userRecord.uid;
      console.log('✅ Auth User erstellt mit UID: ' + uid);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        console.log('⚠️  Auth User existiert bereits, hole UID...');
        const userRecord = await auth.getUserByEmail(email);
        uid = userRecord.uid;
        console.log('   UID: ' + uid);
      } else {
        throw e;
      }
    }

    // 2. Firestore AppUser erstellen
    console.log('Erstelle Firestore AppUser...');
    await db.collection('app_users').doc(uid).set({
      email: email,
      name: 'Alexander Buchner',
      kuerzel: 'BU',
      rolle: 'admin',
      status: 'aktiv',
      klassenIds: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: null
    });
    console.log('✅ Firestore AppUser erstellt');

    console.log('\n📋 Details:');
    console.log('   ID:      ' + uid);
    console.log('   E-Mail:  ' + email);
    console.log('   Name:    Alexander Buchner');
    console.log('   Kürzel:  BU');
    console.log('   Rolle:   Admin');
    console.log('   Passwort: IndusCore2025!');
    console.log('\n✅ FERTIG! Du kannst dich jetzt einloggen.');

  } catch (error) {
    console.error('❌ FEHLER:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

createAdmin();
