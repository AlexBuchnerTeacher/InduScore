// Firebase Admin SDK - User löschen
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-admin-key.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const auth = admin.auth();
const db = admin.firestore();

async function deleteUser() {
  const email = 'alexander.buchner@bs-ie.muenchen.musin.de';
  
  try {
    console.log('🗑️  Lösche User: ' + email);
    
    // Auth User löschen
    try {
      const user = await auth.getUserByEmail(email);
      await auth.deleteUser(user.uid);
      console.log('✅ Auth User gelöscht: ' + user.uid);
      
      // Firestore Dokumente löschen
      await db.collection('app_users').doc(user.uid).delete();
      console.log('✅ Firestore app_users/' + user.uid + ' gelöscht');
    } catch (e) {
      console.log('⚠️  Kein Auth User gefunden');
    }
    
    // Auch aus falscher Collection löschen
    try {
      await db.collection('users').doc('bu-admin').delete();
      console.log('✅ Firestore users/bu-admin gelöscht');
    } catch (e) {}
    
    console.log('\n✅ User komplett gelöscht. Jetzt create_admin.js neu ausführen.');
    
  } catch (error) {
    console.error('❌ Fehler:', error);
  }
  
  process.exit(0);
}

deleteUser();
