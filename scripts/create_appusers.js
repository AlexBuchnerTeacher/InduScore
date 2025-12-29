// Script zum Erstellen von appUser-Dokumenten für existierende Firebase Auth User
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function createAppUsers() {
  console.log('📝 Erstelle appUser-Dokumente für Firebase Auth User...\n');

  const users = [
    {
      uid: 'Xg0Tm6fXDaWWZPQ8IB3zP5QDunL2',
      email: 'alexander.buchner@bs-ie.muenchen.musin.de',
      name: 'Alexander Buchner',
      kuerzel: 'BU',
      rolle: 'admin'
    },
    {
      uid: 'gqCuY6YRwgRo9lovGCiXrzMocQk1',
      email: 'alex.buchner@gmx.de',
      name: 'Alexander Buchner',
      kuerzel: 'BU2',
      rolle: 'admin'
    }
  ];

  for (const user of users) {
    try {
      const docRef = db.collection('app_users').doc(user.uid);
      const doc = await docRef.get();

      if (doc.exists) {
        console.log(`✅ AppUser ${user.kuerzel} (${user.email}) existiert bereits`);
      } else {
        await docRef.set({
          email: user.email.toLowerCase(),
          name: user.name,
          kuerzel: user.kuerzel,
          rolle: user.rolle,
          status: 'aktiv',
          favoriteKlassenIds: [],
          createdAt: admin.firestore.Timestamp.now(),
          lastLoginAt: null
        });
        console.log(`✅ AppUser ${user.kuerzel} (${user.email}) erstellt`);
      }
    } catch (error) {
      console.error(`❌ Fehler bei ${user.kuerzel}:`, error.message);
    }
  }

  console.log('\n✅ Fertig!');
  process.exit(0);
}

createAppUsers();
