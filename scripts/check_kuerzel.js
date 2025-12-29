const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

async function checkKuerzel() {
  console.log('Prüfe app_users Kürzel...\n');
  
  const snapshot = await db.collection('app_users').get();
  
  snapshot.forEach(doc => {
    const data = doc.data();
    console.log('UID:', doc.id);
    console.log('Kürzel:', data.kuerzel);
    console.log('Email:', data.email);
    console.log('---');
  });
  
  console.log('\nTeste Query mit BU-ADMIN...');
  const querySnapshot = await db.collection('app_users')
    .where('kuerzel', '==', 'BU-ADMIN')
    .get();
  
  if (querySnapshot.empty) {
    console.log('❌ Keine Ergebnisse für BU-ADMIN gefunden!');
  } else {
    console.log('✅ Gefunden:', querySnapshot.docs[0].data());
  }
  
  process.exit(0);
}

checkKuerzel();
