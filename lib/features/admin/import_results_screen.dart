import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../data/models/match.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../services/firestore_service.dart';
import '../../services/scoring_service.dart';
import 'widgets/resultado_card.dart';
import 'widgets/team_name_map.dart';

class ImportResultsScreen extends StatefulWidget {
  final String groupId;

  const ImportResultsScreen({super.key, required this.groupId});

  @override
  State<ImportResultsScreen> createState() => _ImportResultsScreenState();
}

class _ImportResultsScreenState extends State<ImportResultsScreen> {
  final _matchRepo = MatchRepository();
  final _groupRepo = GroupRepository();
  final _firestoreService = FirestoreService();
  final _scoringService = ScoringService();
  final _db = FirebaseFirestore.instance;

  List<Match> _matches = [];
  String? _cupId;
  bool _loading = true;
  bool _recalculando = false;
  List<ResultadoImportado> _resultados = [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    try {
      final cup = await _firestoreService.fetchActiveCup();
      if (cup == null) { setState(() => _loading = false); return; }
      _cupId = cup.id;
      final matches = await _matchRepo.fetchGroupMatches(cup.id);
      setState(() { _matches = matches; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _selecionarArquivo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final bytes = result.files.first.bytes;
    if (bytes == null) return;
    await _parsearPlanilha(bytes);
  }

  bool _isX(Data? cell) {
    final v = cell?.value;
    if (v is TextCellValue) return v.value.toString().trim().toLowerCase() == 'x';
    return false;
  }

  String? _cellStr(Data? cell) {
    final v = cell?.value;
    if (v is TextCellValue) {
      final s = v.value.toString().trim();
      return s.isEmpty ? null : s;
    }
    return null;
  }

  int? _cellInt(Data? cell) {
    final v = cell?.value;
    if (v is IntCellValue) return v.value;
    if (v is DoubleCellValue) return v.value.round();
    if (v is TextCellValue) return int.tryParse(v.value.toString().trim());
    return null;
  }

  Data? _cell(List<Data?> row, int idx) => idx < row.length ? row[idx] : null;

  void _processarBloco(
    List<Data?> row, int xi, int ci, int hi, int vi, int ai,
    Map<String, Match> lk, List<ResultadoImportado> out,
  ) {
    if (!_isX(_cell(row, xi))) return;
    final nc = _cellStr(_cell(row, ci));
    final nv = _cellStr(_cell(row, vi));
    final hg = _cellInt(_cell(row, hi));
    final ag = _cellInt(_cell(row, ai));
    if (nc == null || nv == null || hg == null || ag == null) return;
    final hid = teamNameToId[nc];
    final aid = teamNameToId[nv];
    out.add(ResultadoImportado(
      match: hid != null && aid != null ? lk['$hid|$aid'] : null,
      homeGoals: hg, awayGoals: ag, nomeCasa: nc, nomeVisitante: nv,
    ));
  }

  Future<void> _parsearPlanilha(Uint8List bytes) async {
    setState(() => _loading = true);
    try {
      final ex = Excel.decodeBytes(bytes);
      final sheet = ex.tables['Grupos'];
      if (sheet == null) {
        setState(() => _loading = false);
        if (mounted) _mostrarErro('Aba "Grupos" não encontrada na planilha.');
        return;
      }
      final lk = {for (final m in _matches) '${m.homeTeamId}|${m.awayTeamId}': m};
      final res = <ResultadoImportado>[];
      for (final row in sheet.rows) {
        _processarBloco(row, 8, 3, 7, 13, 9, lk, res);
        _processarBloco(row, 21, 16, 20, 26, 22, lk, res);
      }
      setState(() { _resultados = res; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
      if (mounted) _mostrarErro('Erro ao ler a planilha.');
    }
  }

  Future<void> _salvarTodos() async {
    if (_cupId == null) return;
    setState(() => _recalculando = true);
    try {
      final validos = _resultados.where((r) => r.encontrado).toList();
      for (final r in validos) {
        final m = r.match!;
        final col = m.groupId != null
            ? _db.collection('cups').doc(_cupId).collection('groups')
                .doc(m.groupId).collection('matches')
            : _db.collection('cups').doc(_cupId).collection('knockout_matches');
        await col.doc(m.id).set({
          'official_home_goals': r.homeGoals,
          'official_away_goals': r.awayGoals,
          'finished': true,
        }, SetOptions(merge: true));
      }
      MatchRepository.clearCache();
      if (widget.groupId.isNotEmpty) {
        await _recalcularTodos(validos.length);
      } else {
        if (mounted) setState(() => _recalculando = false);
        if (mounted) _mostrarSucesso(validos.length, comRecalculo: false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _recalculando = false);
        _mostrarErro('Erro ao salvar resultados.');
      }
    }
  }

  Future<void> _recalcularTodos(int salvos) async {
    try {
      final members = await _groupRepo.fetchMembers(widget.groupId);
      await Future.wait(members.map((m) async {
        final pts = await _scoringService.calcularPontos(
          groupId: widget.groupId, userId: m.userId, cupId: _cupId!,
        );
        await _groupRepo.updateMemberPoints(widget.groupId, m.userId, pts);
      }));
      if (mounted) {
        setState(() => _recalculando = false);
        _mostrarSucesso(salvos, comRecalculo: true);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _recalculando = false);
        _mostrarErro('Resultados salvos, mas erro no recálculo.');
      }
    }
  }

  void _mostrarSucesso(int n, {required bool comRecalculo}) {
    final extra = comRecalculo ? '' : ' — abra o grupo para recalcular pontos';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$n resultado(s) salvo(s)$extra.'),
      backgroundColor: const Color(0xFF1A6B3C),
    ));
  }

  void _mostrarErro(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final validos = _resultados.where((r) => r.encontrado).length;
    final invalidos = _resultados.length - validos;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Importar Resultados'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF1A6B3C)),
                            onPressed: _selecionarArquivo,
                            icon: const Icon(Icons.upload_file_outlined),
                            label: const Text('Selecionar planilha'),
                          ),
                          if (_resultados.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              '$validos encontrado(s) · $invalidos não encontrado(s)',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 13),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A6B3C)),
                              onPressed: validos > 0 ? _salvarTodos : null,
                              child: Text('Confirmar e salvar ($validos)'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (_resultados.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _resultados.length,
                          itemBuilder: (_, i) =>
                              ResultadoCard(resultado: _resultados[i]),
                        ),
                      )
                    else
                      const Expanded(
                        child: Center(
                          child: Text(
                            'Selecione uma planilha .xlsx\npara visualizar os resultados',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
                if (_recalculando)
                  Container(
                    color: Colors.black.withValues(alpha: 0.35),
                    child: const Center(
                      child: Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 12),
                              Text('Recalculando pontuações...'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
