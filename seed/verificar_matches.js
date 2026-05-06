const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function main() {
  const grupos = await db.collection('cups/2026/groups').get();
  console.log(`Total de grupos encontrados: ${grupos.docs.length}`);
  grupos.docs.forEach(g => console.log(`  - ${g.id}`));

  for (const grupo of grupos.docs) {
    const matches = await db.collection(`cups/2026/groups/${grupo.id}/matches`).get();
    for (const match of matches.docs) {
      const d = match.data();
      console.log(`Grupo ${grupo.id} | Doc: ${match.id} | home: ${d.home_team_id} | away: ${d.away_team_id}`);
    }
  }
  process.exit(0);
}

main().catch(console.error);
