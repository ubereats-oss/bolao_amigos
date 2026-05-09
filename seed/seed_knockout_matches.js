const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();
const CUP_ID = '2026';

function utcTimestamp(date, hour = 12, minute = 0) {
  const [year, month, day] = date.split('-').map(Number);
  return admin.firestore.Timestamp.fromDate(
    new Date(Date.UTC(year, month - 1, day, hour, minute, 0)),
  );
}

const knockoutMatches = [
  // Round of 32
  { id: 'r32_01', phase: 'r32', home_team_id: '2A', away_team_id: '2B', match_time: utcTimestamp('2026-06-28', 12) },
  { id: 'r32_02', phase: 'r32', home_team_id: '1E', away_team_id: '3ABCDF', match_time: utcTimestamp('2026-06-29', 12) },
  { id: 'r32_03', phase: 'r32', home_team_id: '1C', away_team_id: '2F', match_time: utcTimestamp('2026-06-29', 15) },
  { id: 'r32_04', phase: 'r32', home_team_id: '1F', away_team_id: '2C', match_time: utcTimestamp('2026-06-29', 18) },
  { id: 'r32_05', phase: 'r32', home_team_id: '2E', away_team_id: '2I', match_time: utcTimestamp('2026-06-30', 12) },
  { id: 'r32_06', phase: 'r32', home_team_id: '1A', away_team_id: '3CEFHI', match_time: utcTimestamp('2026-06-30', 15) },
  { id: 'r32_07', phase: 'r32', home_team_id: '1I', away_team_id: '3CDFGH', match_time: utcTimestamp('2026-06-30', 18) },
  { id: 'r32_08', phase: 'r32', home_team_id: '1L', away_team_id: '3EHIJK', match_time: utcTimestamp('2026-07-01', 12) },
  { id: 'r32_09', phase: 'r32', home_team_id: '1J', away_team_id: '2H', match_time: utcTimestamp('2026-07-02', 12) },
  { id: 'r32_10', phase: 'r32', home_team_id: '2D', away_team_id: '2G', match_time: utcTimestamp('2026-07-03', 12) },
  { id: 'r32_11', phase: 'r32', home_team_id: '1G', away_team_id: '3AEHIJ', match_time: utcTimestamp('2026-07-01', 15) },
  { id: 'r32_12', phase: 'r32', home_team_id: '1D', away_team_id: '3BEFIJ', match_time: utcTimestamp('2026-07-01', 18) },
  { id: 'r32_13', phase: 'r32', home_team_id: '1H', away_team_id: '2J', match_time: utcTimestamp('2026-07-03', 15) },
  { id: 'r32_14', phase: 'r32', home_team_id: '2K', away_team_id: '2L', match_time: utcTimestamp('2026-07-02', 15) },
  { id: 'r32_15', phase: 'r32', home_team_id: '1B', away_team_id: '3EFGIJ', match_time: utcTimestamp('2026-07-02', 18) },
  { id: 'r32_16', phase: 'r32', home_team_id: '1K', away_team_id: '3DEIJL', match_time: utcTimestamp('2026-07-03', 18) },

  // Round of 16
  { id: 'r16_01', phase: 'r16', home_team_id: 'Wr32_01', away_team_id: 'Wr32_02', match_time: utcTimestamp('2026-07-04', 12) },
  { id: 'r16_02', phase: 'r16', home_team_id: 'Wr32_03', away_team_id: 'Wr32_04', match_time: utcTimestamp('2026-07-04', 15) },
  { id: 'r16_03', phase: 'r16', home_team_id: 'Wr32_05', away_team_id: 'Wr32_06', match_time: utcTimestamp('2026-07-05', 12) },
  { id: 'r16_04', phase: 'r16', home_team_id: 'Wr32_07', away_team_id: 'Wr32_08', match_time: utcTimestamp('2026-07-05', 15) },
  { id: 'r16_05', phase: 'r16', home_team_id: 'Wr32_09', away_team_id: 'Wr32_10', match_time: utcTimestamp('2026-07-06', 12) },
  { id: 'r16_06', phase: 'r16', home_team_id: 'Wr32_11', away_team_id: 'Wr32_12', match_time: utcTimestamp('2026-07-06', 15) },
  { id: 'r16_07', phase: 'r16', home_team_id: 'Wr32_13', away_team_id: 'Wr32_14', match_time: utcTimestamp('2026-07-07', 12) },
  { id: 'r16_08', phase: 'r16', home_team_id: 'Wr32_15', away_team_id: 'Wr32_16', match_time: utcTimestamp('2026-07-07', 15) },

  // Quarter-finals
  { id: 'qf_01', phase: 'qf', home_team_id: 'Wr16_01', away_team_id: 'Wr16_02', match_time: utcTimestamp('2026-07-09', 12) },
  { id: 'qf_02', phase: 'qf', home_team_id: 'Wr16_03', away_team_id: 'Wr16_04', match_time: utcTimestamp('2026-07-10', 12) },
  { id: 'qf_03', phase: 'qf', home_team_id: 'Wr16_05', away_team_id: 'Wr16_06', match_time: utcTimestamp('2026-07-11', 12) },
  { id: 'qf_04', phase: 'qf', home_team_id: 'Wr16_07', away_team_id: 'Wr16_08', match_time: utcTimestamp('2026-07-11', 15) },

  // Semi-finals
  { id: 'sf_01', phase: 'sf', home_team_id: 'Wqf_01', away_team_id: 'Wqf_02', match_time: utcTimestamp('2026-07-14', 12) },
  { id: 'sf_02', phase: 'sf', home_team_id: 'Wqf_03', away_team_id: 'Wqf_04', match_time: utcTimestamp('2026-07-15', 12) },

  // Third place and final
  { id: '3rd_01', phase: '3rd', home_team_id: 'Lsf_01', away_team_id: 'Lsf_02', match_time: utcTimestamp('2026-07-18', 12) },
  { id: 'final_01', phase: 'final', home_team_id: 'Wsf_01', away_team_id: 'Wsf_02', match_time: utcTimestamp('2026-07-19', 15) },
];

async function seed() {
  const cupRef = db.collection('cups').doc(CUP_ID);
  const collection = cupRef.collection('knockout_matches');

  let created = 0;
  let skipped = 0;
  let batch = db.batch();
  let pending = 0;

  for (const match of knockoutMatches) {
    const ref = collection.doc(match.id);
    const snap = await ref.get();
    if (snap.exists) {
      skipped++;
      continue;
    }

    batch.set(ref, {
      home_team_id: match.home_team_id,
      away_team_id: match.away_team_id,
      match_time: match.match_time,
      phase: match.phase,
      official_home_goals: null,
      official_away_goals: null,
      finished: false,
    });
    created++;
    pending++;

    if (pending >= 450) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }

  if (pending > 0) {
    await batch.commit();
  }

  console.log(`Concluido: ${created} criado(s), ${skipped} ja existente(s).`);
}

seed().catch((err) => {
  console.error('Erro:', err);
  process.exit(1);
});
