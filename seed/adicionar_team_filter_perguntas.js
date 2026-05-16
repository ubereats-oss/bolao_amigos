// Adiciona team_filter: 'BRA' nas perguntas de primeiro gol do Brasil (orders 10, 11, 12)
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

async function main() {
  const cupsSnap = await db.collection('cups').get();
  for (const cupDoc of cupsSnap.docs) {
    const questionsSnap = await db
      .collection('cups')
      .doc(cupDoc.id)
      .collection('extra_questions')
      .where('order', 'in', [10, 11, 12])
      .get();

    if (questionsSnap.empty) {
      console.log(`[${cupDoc.id}] Nenhuma pergunta com order 10-12 encontrada.`);
      continue;
    }

    for (const doc of questionsSnap.docs) {
      await doc.ref.update({ team_filter: 'BRA' });
      console.log(`[${cupDoc.id}] Pergunta "${doc.data().question}" → team_filter: BRA`);
    }
  }
  console.log('Concluído.');
}

main().catch(console.error);
