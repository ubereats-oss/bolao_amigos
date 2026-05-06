const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function main() {
  const teams = await db.collection('cups/2026/teams').get();
  console.log(`Total de times: ${teams.docs.length}`);
  teams.docs.forEach(t => {
    console.log(`id: ${t.id} | name: ${t.data().name}`);
  });
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
