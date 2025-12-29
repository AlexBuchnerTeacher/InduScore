// Firebase Admin SDK - Beide Admin User erstellen (BU und BU-ADMIN)
const admin = require('firebase-admin');

const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

const users = [
  {
    email: 'alexander.buchner@bs-ie.muenchen.musin.de',
    password: 'IndusCore2025!',
    name: 'Alexander Buchner',
    kuerzel: 'BU',
    rolle: 'admin'
  },
  {
    email: 'alex.buchner@gmx.de',
    password: 'IndusCore2025!',
    name: 'Alexander Buchner (Admin)',
    kuerzel: 'BU-ADMIN',
    rolle: 'admin'
  }
];

async function createUser(userData) {
  console.log(`\n🚀 Erstelle User ${userData.kuerzel}...`);

  let uid;

  try {
    // 1. Firebase Auth User erstellen
    console.log('Erstelle Firebase Auth User...');
    try {
      const userRecord = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.name
      });
      uid = userRecord.uid;
      console.log('✅ Auth User erstellt mit UID: ' + uid);
    } catch (e) {
      if (e.code === 'auth/email-already-exists') {
        console.log('⚠️  Auth User existiert bereits, hole UID...');
        const userRecord = await auth.getUserByEmail(userData.email);
        uid = userRecord.uid;
        console.log('   UID: ' + uid);
      } else {
        throw e;
      }
    }

    // 2. Firestore AppUser erstellen/aktualisieren
    console.log('Erstelle/Aktualisiere Firestore AppUser...');
    await db.collection('app_users').doc(uid).set({
      email: userData.email,
      name: userData.name,
      kuerzel: userData.kuerzel,
      rolle: userData.rolle,
      status: 'aktiv',
      favoriteKlassenIds: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      lastLoginAt: null
    }, { merge: true }); // merge: true um bestehende Dokumente zu aktualisieren
    console.log('✅ Firestore AppUser erstellt/aktualisiert');

    console.log('\n📋 Details:');
    console.log('   ID:      ' + uid);
    console.log('   E-Mail:  ' + userData.email);
    console.log('   Name:    ' + userData.name);
    console.log('   Kürzel:  ' + userData.kuerzel);
    console.log('   Rolle:   ' + userData.rolle);

  } catch (error) {
    console.error('❌ FEHLER bei ' + userData.kuerzel + ':', error.message);
    throw error;
  }
}

async function createBothUsers() {
  console.log('🚀 Erstelle beide Admin-User...\n');

  try {
    for (const userData of users) {
      await createUser(userData);
    }

    console.log('\n✅ FERTIG! Beide User wurden erstellt.');
    console.log('\nLogin-Optionen:');
    console.log('  - Mit Kürzel "BU" oder "BU-ADMIN"');
    console.log('  - Mit vollständiger Email-Adresse');
    console.log('  - Passwort: IndusCore2025!');

  } catch (error) {
    console.error('\n❌ FEHLER:', error.message);
    process.exit(1);
  }

  process.exit(0);
}

createBothUsers();
