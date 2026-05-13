/**
 * Corrige horários de jogos errados e adiciona perguntas extras faltantes.
 *
 * EXECUÇÃO:
 *   node seed/corrigir_horarios_e_perguntas.js
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
const CUP_ID = '2026';

function brt(dateStr, hour, min = 0) {
  return admin.firestore.Timestamp.fromDate(
    new Date(`${dateStr}T${String(hour).padStart(2, '0')}:${String(min).padStart(2, '0')}:00-03:00`)
  );
}

async function main() {
  const cupRef = db.collection('cups').doc(CUP_ID);

  // ── 1. Corrigir horários de jogos ──────────────────────────────────────────
  console.log('⚽ Corrigindo horários de jogos...');

  const fixes = [
    // match id,           grupo, data correta,  hora, min
    ['d_usa_par',  'd', '2026-06-12', 22, 0],   // 19:00 → 22:00
    ['d_usa_aus',  'd', '2026-06-19', 16, 0],   // 22:00 → 16:00
    ['c_bra_hai',  'c', '2026-06-19', 21, 30],  // 22:00 → 21:30
    ['h_esp_cpv',  'h', '2026-06-15', 13, 0],   // 14 jun → 15 jun
    ['h_ksa_uru',  'h', '2026-06-15', 19, 0],   // 14 jun → 15 jun
    ['k_col_por',  'k', '2026-06-27', 20, 30],  // 28 jun → 27 jun
  ];

  for (const [matchId, groupId, date, hour, min] of fixes) {
    const ref = cupRef
      .collection('groups')
      .doc(groupId)
      .collection('matches')
      .doc(matchId);
    await ref.update({
      match_time: brt(date, hour, min),
      time_confirmed: true,
    });
    console.log(`   ✓ ${matchId} → ${date} ${String(hour).padStart(2,'0')}:${String(min).padStart(2,'0')} BRT`);
  }

  // ── 2. Renomear perguntas extras existentes ────────────────────────────────
  console.log('\n❓ Atualizando texto das perguntas existentes...');
  const questionsRef = cupRef.collection('extra_questions');

  const renames = [
    { order: 3, newText: 'Artilheiro da Copa' },
    { order: 4, newText: 'Nome do jogador que fará o 1° gol na final' },
  ];

  for (const { order, newText } of renames) {
    const snap = await questionsRef.where('order', '==', order).get();
    if (snap.empty) {
      console.log(`   ⚠️  Pergunta order=${order} não encontrada`);
    } else {
      for (const doc of snap.docs) {
        await doc.ref.update({ question: newText });
        console.log(`   ✓ order=${order}: "${doc.data().question}" → "${newText}"`);
      }
    }
  }

  // ── 3. Adicionar novas perguntas extras ────────────────────────────────────
  console.log('\n➕ Adicionando novas perguntas extras...');

  const newQuestions = [
    { question: 'Equipe de melhor campanha na 1ª fase',  type: 'team',   order: 6 },
    { question: 'Equipe de pior campanha na 1ª fase',    type: 'team',   order: 7 },
    { question: 'Equipe de melhor ataque na 1ª fase',    type: 'team',   order: 8 },
    { question: 'Equipe de pior ataque na 1ª fase',      type: 'team',   order: 9 },
    { question: 'Quem fará o primeiro gol do Brasil vs Marrocos?',  type: 'player', order: 10 },
    { question: 'Quem fará o primeiro gol do Brasil vs Haiti?',     type: 'player', order: 11 },
    { question: 'Quem fará o primeiro gol do Brasil vs Escócia?',   type: 'player', order: 12 },
  ];

  for (const q of newQuestions) {
    // Evita duplicata se já existir uma com o mesmo order
    const existing = await questionsRef.where('order', '==', q.order).get();
    if (!existing.empty) {
      console.log(`   ⚠️  Pergunta order=${q.order} já existe — pulando`);
      continue;
    }
    await questionsRef.add(q);
    console.log(`   ✓ order=${q.order}: "${q.question}"`);
  }

  console.log('\n✅ Concluído!');
  process.exit(0);
}

main().catch((err) => {
  console.error('❌ Erro:', err);
  process.exit(1);
});
