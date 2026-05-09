/**
 * SEED — Copa do Mundo 2026
 * Popula o Firestore com times, grupos e jogos da fase de grupos.
 *
 * PRÉ-REQUISITOS:
 *   npm install firebase-admin
 *   Baixe a chave de serviço no Firebase Console:
 *   Configurações do projeto > Contas de serviço > Gerar nova chave privada
 *   Salve como seed/serviceAccountKey.json
 *
 * EXECUÇÃO:
 *   node seed/seed_copa2026.js
 *
 * TIMES PENDENTES (6 vagas definidas em março/2026):
 *   euroa = Repescagem Europa A (Itália / Irlanda do Norte / País de Gales / Bósnia)
 *   eurob = Repescagem Europa B (Ucrânia / Suécia / Polônia / Albânia)
 *   euroc = Repescagem Europa C (Turquia / Romênia / Eslováquia / Kosovo)
 *   eurod = Repescagem Europa D (Dinamarca / Macedônia / Rep. Tcheca / Irlanda)
 *   intc1 = Repescagem Intercontinental 1 (RD Congo / Jamaica / Nova Caledônia)
 *   intc2 = Repescagem Intercontinental 2 (Iraque / Bolívia / Suriname)
 *
 * BANDEIRA FALTANDO:
 *   irn (Irã) não foi baixada pelo script de bandeiras.
 *   Rode: python -c "import urllib.request; urllib.request.urlretrieve('https://flagcdn.com/w80/ir.png', 'assets/flags/irn.png')"
 *
 * HORÁRIOS: todos em BRT (UTC-3). Marcados com ✓ = confirmado, ~ = estimado.
 */
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKeyBolao.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();
const CUP_ID = '2026';
// ─── Helpers ────────────────────────────────────────────────────────────────
/** Cria Timestamp a partir de data BRT */
function brt(dateStr, hour, min = 0) {
  return admin.firestore.Timestamp.fromDate(
    new Date(`${dateStr}T${String(hour).padStart(2, '0')}:${String(min).padStart(2, '0')}:00-03:00`)
  );
}
function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}
// ─── TIMES ──────────────────────────────────────────────────────────────────
const TEAMS = {
  // GRUPO A
  mex:   { name: 'México',                   group: 'a' },
  rsa:   { name: 'África do Sul',             group: 'a' },
  kor:   { name: 'Coreia do Sul',             group: 'a' },
  eurod: { name: 'Repescagem Europa D',       group: 'a', placeholder: true },
  // GRUPO B
  can:   { name: 'Canadá',                    group: 'b' },
  euroa: { name: 'Repescagem Europa A',       group: 'b', placeholder: true },
  qat:   { name: 'Catar',                     group: 'b' },
  sui:   { name: 'Suíça',                     group: 'b' },
  // GRUPO C
  bra:   { name: 'Brasil',                    group: 'c' },
  mar:   { name: 'Marrocos',                  group: 'c' },
  hai:   { name: 'Haiti',                     group: 'c' },
  sco:   { name: 'Escócia',                   group: 'c' },
  // GRUPO D
  usa:   { name: 'Estados Unidos',            group: 'd' },
  par:   { name: 'Paraguai',                  group: 'd' },
  aus:   { name: 'Austrália',                 group: 'd' },
  euroc: { name: 'Repescagem Europa C',       group: 'd', placeholder: true },
  // GRUPO E
  ger:   { name: 'Alemanha',                  group: 'e' },
  cur:   { name: 'Curaçao',                   group: 'e' },
  civ:   { name: 'Costa do Marfim',           group: 'e' },
  ecu:   { name: 'Equador',                   group: 'e' },
  // GRUPO F
  ned:   { name: 'Holanda',                   group: 'f' },
  jpn:   { name: 'Japão',                     group: 'f' },
  eurob: { name: 'Repescagem Europa B',       group: 'f', placeholder: true },
  tun:   { name: 'Tunísia',                   group: 'f' },
  // GRUPO G
  bel:   { name: 'Bélgica',                   group: 'g' },
  egy:   { name: 'Egito',                     group: 'g' },
  irn:   { name: 'Irã',                       group: 'g' },
  nzl:   { name: 'Nova Zelândia',             group: 'g' },
  // GRUPO H
  esp:   { name: 'Espanha',                   group: 'h' },
  cpv:   { name: 'Cabo Verde',                group: 'h' },
  ksa:   { name: 'Arábia Saudita',            group: 'h' },
  uru:   { name: 'Uruguai',                   group: 'h' },
  // GRUPO I
  fra:   { name: 'França',                    group: 'i' },
  sen:   { name: 'Senegal',                   group: 'i' },
  intc2: { name: 'Repescagem Intercontinental 2', group: 'i', placeholder: true },
  nor:   { name: 'Noruega',                   group: 'i' },
  // GRUPO J
  arg:   { name: 'Argentina',                 group: 'j' },
  alg:   { name: 'Argélia',                   group: 'j' },
  aut:   { name: 'Áustria',                   group: 'j' },
  jor:   { name: 'Jordânia',                  group: 'j' },
  // GRUPO K
  por:   { name: 'Portugal',                  group: 'k' },
  intc1: { name: 'Repescagem Intercontinental 1', group: 'k', placeholder: true },
  uzb:   { name: 'Uzbequistão',               group: 'k' },
  col:   { name: 'Colômbia',                  group: 'k' },
  // GRUPO L
  eng:   { name: 'Inglaterra',                group: 'l' },
  cro:   { name: 'Croácia',                   group: 'l' },
  pan:   { name: 'Panamá',                    group: 'l' },
  gha:   { name: 'Gana',                      group: 'l' },
};
// ─── JOGOS DA FASE DE GRUPOS ─────────────────────────────────────────────────
// Formato: [home, away, data, hora_brt, minuto_brt, confirmado]
// ✓ = horário confirmado por fonte oficial  ~ = estimado
const GROUP_MATCHES = {
  a: [
    // Rodada 1
    ['mex',  'rsa',   '2026-06-11', 20, 0,  true],   // ✓ Abertura — Estádio Azteca
    ['kor',  'eurod', '2026-06-12', 23, 0,  false],  // ~ Guadalajara
    // Rodada 2
    ['rsa',  'eurod', '2026-06-18', 13, 0,  true],   // ✓ Atlanta
    ['mex',  'kor',   '2026-06-18', 22, 0,  true],   // ✓ Guadalajara
    // Rodada 3
    ['mex',  'eurod', '2026-06-24', 22, 0,  false],  // ~ Cidade do México
    ['kor',  'rsa',   '2026-06-24', 22, 0,  false],  // ~ Guadalajara
  ],
  b: [
    // Rodada 1
    ['can',  'euroa', '2026-06-12', 16, 0,  false],  // ~ Toronto
    ['qat',  'sui',   '2026-06-13', 16, 0,  true],   // ✓ São Francisco
    // Rodada 2
    ['can',  'qat',   '2026-06-18', 16, 0,  false],  // ~ Los Angeles
    ['sui',  'euroa', '2026-06-18', 19, 0,  false],  // ~ Vancouver
    // Rodada 3
    ['sui',  'can',   '2026-06-24', 16, 0,  true],   // ✓ Vancouver
    ['euroa','qat',   '2026-06-24', 16, 0,  true],   // ✓ Seattle
  ],
  c: [
    // Rodada 1
    ['bra',  'mar',   '2026-06-13', 19, 0,  true],   // ✓ MetLife — Nova Jersey
    ['hai',  'sco',   '2026-06-13', 22, 0,  true],   // ✓ Gillette — Boston
    // Rodada 2
    ['sco',  'mar',   '2026-06-19', 19, 0,  true],   // ✓ Gillette — Boston
    ['bra',  'hai',   '2026-06-19', 22, 0,  true],   // ✓ Lincoln — Filadélfia
    // Rodada 3
    ['sco',  'bra',   '2026-06-24', 19, 0,  true],   // ✓ Hard Rock — Miami
    ['mar',  'hai',   '2026-06-24', 19, 0,  true],   // ✓ Mercedes-Benz — Atlanta
  ],
  d: [
    // Rodada 1
    ['usa',  'par',   '2026-06-12', 19, 0,  false],  // ~ Los Angeles
    ['aus',  'euroc', '2026-06-12', 22, 0,  false],  // ~ Vancouver
    // Rodada 2
    ['usa',  'aus',   '2026-06-19', 22, 0,  true],   // ✓ Seattle (Lumen Field)
    ['euroc','par',   '2026-06-20',  1, 0,  true],   // ✓ São Francisco
    // Rodada 3
    ['euroc','usa',   '2026-06-25', 23, 0,  true],   // ✓ Los Angeles
    ['par',  'aus',   '2026-06-25', 23, 0,  true],   // ✓ São Francisco
  ],
  e: [
    // Rodada 1
    ['ger',  'cur',   '2026-06-14', 14, 0,  true],   // ✓ Houston
    ['civ',  'ecu',   '2026-06-14', 20, 0,  true],   // ✓ Filadélfia
    // Rodada 2
    ['ger',  'civ',   '2026-06-20', 17, 0,  true],   // ✓ Toronto
    ['ecu',  'cur',   '2026-06-20', 21, 0,  true],   // ✓ Kansas City
    // Rodada 3
    ['ecu',  'ger',   '2026-06-25', 17, 0,  true],   // ✓ MetLife — Nova York
    ['cur',  'civ',   '2026-06-25', 17, 0,  true],   // ✓ Filadélfia
  ],
  f: [
    // Rodada 1
    ['ned',  'tun',   '2026-06-13', 14, 0,  false],  // ~ estimado
    ['jpn',  'eurob', '2026-06-13', 20, 0,  false],  // ~ estimado
    // Rodada 2
    ['ned',  'jpn',   '2026-06-20', 14, 0,  false],  // ~ estimado
    ['eurob','tun',   '2026-06-20', 18, 0,  false],  // ~ estimado
    // Rodada 3
    ['jpn',  'tun',   '2026-06-25', 16, 0,  false],  // ~ estimado
    ['eurob','ned',   '2026-06-25', 16, 0,  false],  // ~ estimado
  ],
  g: [
    // Rodada 1
    ['bel',  'egy',   '2026-06-15', 16, 0,  false],  // ~ Seattle
    ['irn',  'nzl',   '2026-06-15', 22, 0,  false],  // ~ Los Angeles
    // Rodada 2
    ['bel',  'irn',   '2026-06-21', 16, 0,  true],   // ✓ Los Angeles
    ['nzl',  'egy',   '2026-06-21', 22, 0,  true],   // ✓ Vancouver
    // Rodada 3
    ['egy',  'irn',   '2026-06-27',  0, 0,  false],  // ~ Seattle
    ['nzl',  'bel',   '2026-06-27',  0, 0,  false],  // ~ Vancouver
  ],
  h: [
    // Rodada 1
    ['esp',  'cpv',   '2026-06-14', 13, 0,  true],   // ✓ Atlanta
    ['ksa',  'uru',   '2026-06-14', 19, 0,  true],   // ✓ Miami
    // Rodada 2
    ['esp',  'ksa',   '2026-06-21', 13, 0,  true],   // ✓ Atlanta
    ['uru',  'cpv',   '2026-06-21', 19, 0,  true],   // ✓ Miami
    // Rodada 3
    ['cpv',  'ksa',   '2026-06-26', 21, 0,  true],   // ✓ Houston
    ['uru',  'esp',   '2026-06-26', 21, 0,  true],   // ✓ Guadalajara
  ],
  i: [
    // Rodada 1
    ['fra',   'sen',   '2026-06-16', 16, 0,  true],  // ✓ Nova York
    ['intc2', 'nor',   '2026-06-16', 19, 0,  true],  // ✓ Boston
    // Rodada 2
    ['fra',   'intc2', '2026-06-22', 18, 0,  true],  // ✓ Filadélfia
    ['nor',   'sen',   '2026-06-22', 21, 0,  true],  // ✓ Nova York
    // Rodada 3
    ['nor',   'fra',   '2026-06-26', 16, 0,  true],  // ✓ Boston
    ['sen',   'intc2', '2026-06-26', 16, 0,  true],  // ✓ Toronto
  ],
  j: [
    // Rodada 1
    ['arg',  'alg',   '2026-06-16', 22, 0,  true],  // ✓ Kansas City
    ['aut',  'jor',   '2026-06-17',  1, 0,  true],  // ✓ São Francisco
    // Rodada 2
    ['arg',  'aut',   '2026-06-22', 14, 0,  true],  // ✓ Dallas
    ['jor',  'alg',   '2026-06-23',  0, 0,  true],  // ✓ São Francisco
    // Rodada 3
    ['alg',  'aut',   '2026-06-27', 23, 0,  true],  // ✓ Kansas City
    ['jor',  'arg',   '2026-06-27', 23, 0,  true],  // ✓ Dallas
  ],
  k: [
    // Rodada 1
    ['por',   'intc1', '2026-06-17', 14, 0,  true],  // ✓ Houston
    ['uzb',   'col',   '2026-06-17', 23, 0,  true],  // ✓ Cidade do México
    // Rodada 2
    ['por',   'uzb',   '2026-06-23', 14, 0,  true],  // ✓ Houston
    ['col',   'intc1', '2026-06-23', 23, 0,  true],  // ✓ Guadalajara
    // Rodada 3
    ['col',   'por',   '2026-06-28', 20, 30, true],  // ✓ Miami
    ['intc1', 'uzb',   '2026-06-28', 20, 30, true],  // ✓ Atlanta
  ],
  l: [
    // Rodada 1
    ['eng',  'cro',   '2026-06-17', 17, 0,  true],  // ✓ Dallas
    ['gha',  'pan',   '2026-06-17', 20, 0,  true],  // ✓ Toronto
    // Rodada 2
    ['eng',  'gha',   '2026-06-23', 17, 0,  true],  // ✓ Boston
    ['pan',  'cro',   '2026-06-23', 20, 0,  true],  // ✓ Toronto
    // Rodada 3
    ['cro',  'gha',   '2026-06-28', 18, 0,  true],  // ✓ Filadélfia
    ['pan',  'eng',   '2026-06-28', 18, 0,  true],  // ✓ Nova York
  ],
};
// ─── SEED ────────────────────────────────────────────────────────────────────
async function seed() {
  console.log('🌱 Iniciando seed da Copa do Mundo 2026...\n');
  const cupRef = db.collection('cups').doc(CUP_ID);
  // 1. Documento da Copa
  console.log('📋 Criando documento da copa...');
  await cupRef.set({
    name: 'Copa do Mundo 2026',
    year: 2026,
    active: true,
    starts_at: brt('2026-06-11', 20, 0),
  });
  // 2. Times
  console.log('🏳️  Criando times...');
  const teamsRef = cupRef.collection('teams');
  for (const [id, team] of Object.entries(TEAMS)) {
    await teamsRef.doc(id).set({ name: team.name });
  }
  console.log(`   ${Object.keys(TEAMS).length} times criados.`);
  // 3. Grupos
  console.log('📁 Criando grupos...');
  const groupNames = {
    a: 'Grupo A', b: 'Grupo B', c: 'Grupo C', d: 'Grupo D',
    e: 'Grupo E', f: 'Grupo F', g: 'Grupo G', h: 'Grupo H',
    i: 'Grupo I', j: 'Grupo J', k: 'Grupo K', l: 'Grupo L',
  };
  const groupsRef = cupRef.collection('groups');
  for (const [id, name] of Object.entries(groupNames)) {
    await groupsRef.doc(id).set({ name });
  }
  console.log(`   12 grupos criados.`);
  // 4. Jogos da fase de grupos
  console.log('⚽ Criando jogos da fase de grupos...');
  let totalMatches = 0;
  for (const [groupId, matches] of Object.entries(GROUP_MATCHES)) {
    const matchesRef = groupsRef.doc(groupId).collection('matches');
    for (const [home, away, date, hour, min, confirmed] of matches) {
      const matchId = `${groupId}_${home}_${away}`;
      await matchesRef.doc(matchId).set({
        home_team_id: home,
        away_team_id: away,
        match_time: brt(date, hour, min),
        phase: 'group',
        group_id: groupId,
        official_home_goals: null,
        official_away_goals: null,
        finished: false,
        time_confirmed: confirmed,
      });
      totalMatches++;
    }
    await sleep(200);
  }
  console.log(`   ${totalMatches} jogos criados.`);
  // 5. Perguntas extras padrão
  console.log('❓ Criando perguntas extras...');
  const questionsRef = cupRef.collection('extra_questions');
  const defaultQuestions = [
    { question: 'Quem será o Campeão?',          type: 'team',   order: 1 },
    { question: 'Quem será o Vice-Campeão?',      type: 'team',   order: 2 },
    { question: 'Quem será o Artilheiro?',        type: 'player', order: 3 },
    { question: 'Quem fará o primeiro gol da Final?', type: 'player', order: 4 },
    { question: 'Quem será o Goleiro menos vazado?',  type: 'player', order: 5 },
  ];
  for (const q of defaultQuestions) {
    await questionsRef.add(q);
  }
  console.log(`   ${defaultQuestions.length} perguntas criadas.`);
  console.log('\n✅ Seed concluído com sucesso!');
  console.log('\n⚠️  ATENÇÃO:');
  console.log('   - 6 times placeholder ainda aguardam definição (repescagens de março/2026)');
  console.log('   - Horários marcados com ~ são estimados. Verifique em https://www.fifa.com');
  console.log('   - Bandeira do Irã (irn.png) precisa ser baixada manualmente:');
  console.log('     python -c "import urllib.request; urllib.request.urlretrieve(\'https://flagcdn.com/w80/ir.png\', \'assets/flags/irn.png\')"');
  process.exit(0);
}
seed().catch((err) => {
  console.error('❌ Erro no seed:', err);
  process.exit(1);
});
