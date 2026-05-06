const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function main() {
  const teamsRef = db.collection('cups/2026/teams');
  const teams = await teamsRef.get();

  for (const doc of teams.docs) {
    if (doc.id !== doc.id.toLowerCase()) {
      const novoId = doc.id.toLowerCase();
      console.log(`Corrigindo: ${doc.id} -> ${novoId} | ${doc.data().name}`);
      const batch = db.batch();
      batch.set(teamsRef.doc(novoId), doc.data());
      batch.delete(teamsRef.doc(doc.id));
      await batch.commit();
    }
  }

  console.log('Concluído!');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
