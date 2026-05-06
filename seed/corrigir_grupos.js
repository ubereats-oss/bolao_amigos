const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// Correções por grupo: { grupo: { de: para } }
const CORRECOES = {
  'a': { 'bih': 'cze' },
  'b': { 'tur': 'bih' },
  'd': { 'cze': 'tur' },
};

function corrigir(id, mapa) {
  return mapa[id] ?? id;
}

function corrigirDocId(docId, mapa) {
  let result = docId;
  for (const [de, para] of Object.entries(mapa)) {
    result = result.replace(new RegExp(`\\b${de}\\b`, 'g'), para);
  }
  return result;
}

async function main() {
  for (const [grupoId, mapa] of Object.entries(CORRECOES)) {
    const matchesRef = db.collection(`cups/2026/groups/${grupoId}/matches`);
    const matches = await matchesRef.get();

    for (const match of matches.docs) {
      const d = match.data();
      const homeCorr = corrigir(d.home_team_id, mapa);
      const awayCorr = corrigir(d.away_team_id, mapa);
      const docIdCorr = corrigirDocId(match.id, mapa);

      const precisaCorrigir =
        homeCorr !== d.home_team_id ||
        awayCorr !== d.away_team_id ||
        docIdCorr !== match.id;

      if (!precisaCorrigir) continue;

      console.log(`Grupo ${grupoId} | ${match.id} -> ${docIdCorr} | home: ${d.home_team_id}->${homeCorr} | away: ${d.away_team_id}->${awayCorr}`);

      const batch = db.batch();
      batch.set(matchesRef.doc(docIdCorr), {
        ...d,
        home_team_id: homeCorr,
        away_team_id: awayCorr,
      });
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
