const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

async function main() {
  const groups = await db.collection('bolao_groups').get();
  const batch = db.batch();
  let count = 0;

  for (const group of groups.docs) {
    const data = group.data();
    const code = String(data.invite_code || '').trim().toUpperCase();
    if (!code) continue;

    batch.set(db.collection('invite_codes').doc(code), {
      group_id: group.id,
      created_by: data.admin_uid || '',
      created_at: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    count++;
  }

  await batch.commit();
  console.log(`${count} código(s) migrado(s).`);
  process.exit(0);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
