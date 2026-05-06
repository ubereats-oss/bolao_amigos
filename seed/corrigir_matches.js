const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Mapeamento: id_errado_no_firestore -> id_correto
const ID_MAP = {
  'eurod': 'bih',
  'euroa': 'tur',
  'eurob': 'swe',
  'euroc': 'cze',
  'intc1': 'cod',
  'intc2': 'irq',
};

function corrigirTeamId(id) {
  if (!id) return id;
  const lower = id.toLowerCase();
  return ID_MAP[lower] ?? lower;
}

function corrigirDocId(docId) {
  let result = docId;
  for (const [errado, correto] of Object.entries(ID_MAP)) {
    result = result.replace(errado, correto);
  }
  return result;
}

async function main() {
  const grupos = await db.collection('cups/2026/groups').get();

  for (const grupo of grupos.docs) {
    const matchesRef = db.collection(`cups/2026/groups/${grupo.id}/matches`);
    const matches = await matchesRef.get();

    for (const match of matches.docs) {
      const d = match.data();
      const homeCorr = corrigirTeamId(d.home_team_id);
      const awayCorr = corrigirTeamId(d.away_team_id);
      const docIdCorr = corrigirDocId(match.id);

      const precisaCorrigir =
        homeCorr !== d.home_team_id ||
        awayCorr !== d.away_team_id ||
        docIdCorr !== match.id;

      if (!precisaCorrigir) continue;

      console.log(`Corrigindo: ${grupo.id}/${match.id} -> ${docIdCorr} | home: ${d.home_team_id}->${homeCorr} | away: ${d.away_team_id}->${awayCorr}`);

      const batch = db.batch();
      // Cria documento correto
      batch.set(matchesRef.doc(docIdCorr), {
        ...d,
        home_team_id: homeCorr,
        away_team_id: awayCorr,
      });
      // Deleta documento errado
      if (docIdCorr !== match.id) {
        batch.delete(matchesRef.doc(match.id));
      }
      await batch.commit();
    }
  }

  console.log('Concluído!');
  process.exit(0);
}

main().catch(e => { console.error(e); process.exit(1); });
