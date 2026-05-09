// Chaveamento da fase eliminatória
// Slots de 3º colocado: lista de grupos candidatos
// O app resolve qual time ocupa cada slot em função dos palpites do usuário.

class BracketSlot {
  /// Ex: '1A' = 1º do grupo A | '2B' = 2º do grupo B | '3ABCDF' = melhor 3º entre grupos A,B,C,D,F
  final String code;
  const BracketSlot(this.code);

  bool get isThird => code.startsWith('3');

  /// Grupos candidatos para slots de 3º colocado (ex: '3ABCDF' → ['A','B','C','D','F'])
  List<String> get thirdGroups =>
      isThird ? code.substring(1).split('').map((g) => g.toLowerCase()).toList() : [];
}

class BracketMatchDef {
  final String id; // identificador único do confronto (ex: 'r32_01')
  final String phase; // 'r32' | 'r16' | 'qf' | 'sf' | '3rd' | 'final'
  final BracketSlot home;
  final BracketSlot away;

  const BracketMatchDef({
    required this.id,
    required this.phase,
    required this.home,
    required this.away,
  });
}

class BracketData {
  static const List<String> phases = ['r32', 'r16', 'qf', 'sf', 'final', '3rd'];

  static const Map<String, String> phaseLabels = {
    'r32': 'Rodada de 32',
    'r16': 'Oitavas de Final',
    'qf': 'Quartas de Final',
    'sf': 'Semifinais',
    'final': 'Final',
    '3rd': '3º Lugar',
  };

  /// Round of 32 — chaveamento oficial da fase eliminatória
  static const List<BracketMatchDef> r32 = [
    BracketMatchDef(
        id: 'r32_01',
        phase: 'r32',
        home: BracketSlot('2A'),
        away: BracketSlot('2B')),
    BracketMatchDef(
        id: 'r32_02',
        phase: 'r32',
        home: BracketSlot('1E'),
        away: BracketSlot('3ABCDF')),
    BracketMatchDef(
        id: 'r32_03',
        phase: 'r32',
        home: BracketSlot('1C'),
        away: BracketSlot('2F')),
    BracketMatchDef(
        id: 'r32_04',
        phase: 'r32',
        home: BracketSlot('1F'),
        away: BracketSlot('2C')),
    BracketMatchDef(
        id: 'r32_05',
        phase: 'r32',
        home: BracketSlot('2E'),
        away: BracketSlot('2I')),
    BracketMatchDef(
        id: 'r32_06',
        phase: 'r32',
        home: BracketSlot('1A'),
        away: BracketSlot('3CEFHI')),
    BracketMatchDef(
        id: 'r32_07',
        phase: 'r32',
        home: BracketSlot('1I'),
        away: BracketSlot('3CDFGH')),
    BracketMatchDef(
        id: 'r32_08',
        phase: 'r32',
        home: BracketSlot('1L'),
        away: BracketSlot('3EHIJK')),
    BracketMatchDef(
        id: 'r32_09',
        phase: 'r32',
        home: BracketSlot('1J'),
        away: BracketSlot('2H')),
    BracketMatchDef(
        id: 'r32_10',
        phase: 'r32',
        home: BracketSlot('2D'),
        away: BracketSlot('2G')),
    BracketMatchDef(
        id: 'r32_11',
        phase: 'r32',
        home: BracketSlot('1G'),
        away: BracketSlot('3AEHIJ')),
    BracketMatchDef(
        id: 'r32_12',
        phase: 'r32',
        home: BracketSlot('1D'),
        away: BracketSlot('3BEFIJ')),
    BracketMatchDef(
        id: 'r32_13',
        phase: 'r32',
        home: BracketSlot('1H'),
        away: BracketSlot('2J')),
    BracketMatchDef(
        id: 'r32_14',
        phase: 'r32',
        home: BracketSlot('2K'),
        away: BracketSlot('2L')),
    BracketMatchDef(
        id: 'r32_15',
        phase: 'r32',
        home: BracketSlot('1B'),
        away: BracketSlot('3EFGIJ')),
    BracketMatchDef(
        id: 'r32_16',
        phase: 'r32',
        home: BracketSlot('1K'),
        away: BracketSlot('3DEIJL')),
  ];

  /// Oitavas: vencedores dos pares de jogos do R32
  /// W(id) = vencedor do jogo com aquele id
  static const List<BracketMatchDef> r16 = [
    BracketMatchDef(
        id: 'r16_01',
        phase: 'r16',
        home: BracketSlot('Wr32_01'),
        away: BracketSlot('Wr32_02')),
    BracketMatchDef(
        id: 'r16_02',
        phase: 'r16',
        home: BracketSlot('Wr32_03'),
        away: BracketSlot('Wr32_04')),
    BracketMatchDef(
        id: 'r16_03',
        phase: 'r16',
        home: BracketSlot('Wr32_05'),
        away: BracketSlot('Wr32_06')),
    BracketMatchDef(
        id: 'r16_04',
        phase: 'r16',
        home: BracketSlot('Wr32_07'),
        away: BracketSlot('Wr32_08')),
    BracketMatchDef(
        id: 'r16_05',
        phase: 'r16',
        home: BracketSlot('Wr32_09'),
        away: BracketSlot('Wr32_10')),
    BracketMatchDef(
        id: 'r16_06',
        phase: 'r16',
        home: BracketSlot('Wr32_11'),
        away: BracketSlot('Wr32_12')),
    BracketMatchDef(
        id: 'r16_07',
        phase: 'r16',
        home: BracketSlot('Wr32_13'),
        away: BracketSlot('Wr32_14')),
    BracketMatchDef(
        id: 'r16_08',
        phase: 'r16',
        home: BracketSlot('Wr32_15'),
        away: BracketSlot('Wr32_16')),
  ];

  static const List<BracketMatchDef> qf = [
    BracketMatchDef(
        id: 'qf_01',
        phase: 'qf',
        home: BracketSlot('Wr16_01'),
        away: BracketSlot('Wr16_02')),
    BracketMatchDef(
        id: 'qf_02',
        phase: 'qf',
        home: BracketSlot('Wr16_03'),
        away: BracketSlot('Wr16_04')),
    BracketMatchDef(
        id: 'qf_03',
        phase: 'qf',
        home: BracketSlot('Wr16_05'),
        away: BracketSlot('Wr16_06')),
    BracketMatchDef(
        id: 'qf_04',
        phase: 'qf',
        home: BracketSlot('Wr16_07'),
        away: BracketSlot('Wr16_08')),
  ];

  static const List<BracketMatchDef> sf = [
    BracketMatchDef(
        id: 'sf_01',
        phase: 'sf',
        home: BracketSlot('Wqf_01'),
        away: BracketSlot('Wqf_02')),
    BracketMatchDef(
        id: 'sf_02',
        phase: 'sf',
        home: BracketSlot('Wqf_03'),
        away: BracketSlot('Wqf_04')),
  ];

  static const List<BracketMatchDef> thirdPlace = [
    BracketMatchDef(
        id: '3rd_01',
        phase: '3rd',
        home: BracketSlot('Lsf_01'),
        away: BracketSlot('Lsf_02')),
  ];

  static const List<BracketMatchDef> finalMatch = [
    BracketMatchDef(
        id: 'final_01',
        phase: 'final',
        home: BracketSlot('Wsf_01'),
        away: BracketSlot('Wsf_02')),
  ];

  static List<BracketMatchDef> get allMatches =>
      [...r32, ...r16, ...qf, ...sf, ...thirdPlace, ...finalMatch];

  static List<BracketMatchDef> matchesForPhase(String phase) =>
      allMatches.where((m) => m.phase == phase).toList();

  /// Grupos de A a L
  static const List<String> groups = [
    'A',
    'B',
    'C',
    'D',
    'E',
    'F',
    'G',
    'H',
    'I',
    'J',
    'K',
    'L'
  ];
}
