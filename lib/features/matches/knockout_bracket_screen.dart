import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/bracket_data.dart';
import '../../data/models/cup.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/models/knockout_prediction.dart';
import '../../data/repositories/knockout_prediction_repository.dart';
import 'bracket_engine.dart';
import 'widgets/bracket_match_card.dart';

class KnockoutBracketScreen extends StatefulWidget {
  final String groupId;
  final Cup cup;
  final List<Match> groupMatches;
  // null = sem palpite salvo para aquele jogo
  final Map<String, List<int>?> groupPredictions;
  final Map<String, Match> knockoutMatchesById;
  final Map<String, Team> teams;
  final void Function(String phase)? onPhaseChanged;

  const KnockoutBracketScreen({
    super.key,
    required this.groupId,
    required this.cup,
    required this.groupMatches,
    required this.groupPredictions,
    required this.knockoutMatchesById,
    required this.teams,
    this.onPhaseChanged,
  });

  @override
  State<KnockoutBracketScreen> createState() => _KnockoutBracketScreenState();
}

class _KnockoutBracketScreenState extends State<KnockoutBracketScreen>
    with SingleTickerProviderStateMixin {
  final _knockoutRepo = KnockoutPredictionRepository();

  late TabController _tabController;

  Map<String, KnockoutPrediction> _koPreds = {};
  final Map<String, List<int>> _localPalpites = {};
  final Map<String, String?> _localWinners = {};
  final Set<String> _localScoreSet = {};
  String _uid = '';
  final Map<String, bool> _saving = {};
  bool _savingAll = false;
  bool _loading = true;
  String? _erro;
  List<ResolvedMatch> _resolved = [];
  Map<String, List<String>> _groupTeams = {};

  static const List<String> _tabPhases = ['r32', 'r16', 'qf', 'sf', 'final'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabPhases.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        widget.onPhaseChanged?.call(_tabPhases[_tabController.index]);
      }
    });
    _inicializar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(KnockoutBracketScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.groupPredictions, widget.groupPredictions)) {
      _recomputar();
    }
  }

  Future<void> _inicializar() async {
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      _uid = uid;
      final koPreds = await _knockoutRepo.fetchAll(widget.groupId, uid);

      final Map<String, List<String>> groupTeams = {};
      for (final m in widget.groupMatches) {
        if (m.groupId == null) continue;
        groupTeams.putIfAbsent(m.groupId!, () => []);
        if (!groupTeams[m.groupId]!.contains(m.homeTeamId)) {
          groupTeams[m.groupId]!.add(m.homeTeamId);
        }
        if (!groupTeams[m.groupId]!.contains(m.awayTeamId)) {
          groupTeams[m.groupId]!.add(m.awayTeamId);
        }
      }

      final Map<String, List<int>> localPalpites = {};
      final Map<String, String?> localWinners = {};
      final Set<String> localScoreSet = {};
      for (final def in BracketData.allMatches) {
        final saved = koPreds[def.id];
        if (saved?.homeGoals != null && saved?.awayGoals != null) {
          localPalpites[def.id] = [saved!.homeGoals!, saved.awayGoals!];
          localScoreSet.add(def.id);
        } else {
          localPalpites[def.id] = [0, 0];
        }
        localWinners[def.id] = saved?.winner;
      }

      setState(() {
        _koPreds = koPreds;
        _groupTeams = groupTeams;
        _localPalpites.addAll(localPalpites);
        _localWinners.addAll(localWinners);
        _localScoreSet.addAll(localScoreSet);
        _loading = false;
      });

      _recomputar();
    } catch (e) {
      debugPrint('_inicializar knockout: $e');
      setState(() {
        _erro = 'Erro ao carregar mata-mata.';
        _loading = false;
      });
    }
  }

  Map<String, KnockoutPrediction> _efectivePreds() {
    final Map<String, KnockoutPrediction> effective = {
      for (final e in _koPreds.entries) e.key: e.value,
    };
    for (final entry in _localWinners.entries) {
      final slotId = entry.key;
      final winner = entry.value;
      if (winner == null) continue;
      if (effective.containsKey(slotId)) {
        final ex = effective[slotId]!;
        effective[slotId] = KnockoutPrediction(
          slotId: ex.slotId,
          userId: ex.userId,
          homeGoals: ex.homeGoals,
          awayGoals: ex.awayGoals,
          winner: winner,
          savedAt: ex.savedAt,
        );
      } else {
        effective[slotId] = KnockoutPrediction(
          slotId: slotId,
          userId: _uid,
          winner: winner,
          savedAt: DateTime.now(),
        );
      }
    }
    return effective;
  }

  void _recomputar() {
    final engine = BracketEngine(
      groupMatches: widget.groupMatches,
      groupPredictions: widget.groupPredictions,
      knockoutPredictions: _efectivePreds(),
      groupTeams: _groupTeams,
    );
    setState(() {
      _resolved = engine.resolveAll();
    });
  }

  void _incrementar(String slotId, int side) {
    if (widget.cup.isLocked) return;
    setState(() {
      _localPalpites[slotId]![side] =
          (_localPalpites[slotId]![side] + 1).clamp(0, 99);
      _localScoreSet.add(slotId);
    });
    _autoAtualizarVencedor(slotId);
  }

  void _decrementar(String slotId, int side) {
    if (widget.cup.isLocked) return;
    setState(() {
      _localPalpites[slotId]![side] =
          (_localPalpites[slotId]![side] - 1).clamp(0, 99);
      _localScoreSet.add(slotId);
    });
    _autoAtualizarVencedor(slotId);
  }

  void _autoAtualizarVencedor(String slotId) {
    final gols = _localPalpites[slotId];
    if (gols == null || gols[0] == gols[1]) return;
    ResolvedMatch? rm;
    for (final r in _resolved) {
      if (r.def.id == slotId) {
        rm = r;
        break;
      }
    }
    if (rm == null) return;
    final winner = gols[0] > gols[1] ? rm.homeTeamId : rm.awayTeamId;
    if (winner != null) {
      setState(() => _localWinners[slotId] = winner);
      _recomputar();
    }
  }

  void _selecionarVencedor(String slotId, String teamId) {
    setState(() => _localWinners[slotId] = teamId);
    _recomputar();
  }

  KnockoutPrediction _buildPred(String uid, ResolvedMatch rm) {
    final hasScore = _localScoreSet.contains(rm.def.id);
    final gols = hasScore ? _localPalpites[rm.def.id] : null;
    String? winner = _localWinners[rm.def.id];
    if (gols != null && gols[0] != gols[1]) {
      winner = gols[0] > gols[1] ? rm.homeTeamId : rm.awayTeamId;
    }
    return KnockoutPrediction(
      slotId: rm.def.id,
      userId: uid,
      homeGoals: gols?[0],
      awayGoals: gols?[1],
      winner: winner,
      savedAt: DateTime.now(),
    );
  }

  Future<void> _salvar(ResolvedMatch rm) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _saving[rm.def.id] = true);
    try {
      final pred = _buildPred(uid, rm);
      await _knockoutRepo.save(widget.groupId, pred);
      setState(() {
        _koPreds[rm.def.id] = pred;
        _localWinners[rm.def.id] = pred.winner;
      });
      _recomputar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Palpite salvo!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF1A6B3C),
        ));
      }
    } catch (e) {
      debugPrint('_salvar knockout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao salvar palpite.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving[rm.def.id] = false);
    }
  }

  Future<void> _salvarTodos(List<ResolvedMatch> matches) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final salvando = matches.where((r) {
      return r.canPredict &&
          (_localScoreSet.contains(r.def.id) ||
              _localWinners[r.def.id] != null);
    }).toList();
    if (salvando.isEmpty) return;
    setState(() => _savingAll = true);
    try {
      for (final rm in salvando) {
        final pred = _buildPred(uid, rm);
        await _knockoutRepo.save(widget.groupId, pred);
        _koPreds[rm.def.id] = pred;
        _localWinners[rm.def.id] = pred.winner;
      }
      _recomputar();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${salvando.length} palpites salvos!'),
          backgroundColor: const Color(0xFF1A6B3C),
        ));
      }
    } catch (e) {
      debugPrint('_salvarTodos knockout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao salvar palpites.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_erro != null) return Center(child: Text(_erro!));

    return Column(
      children: [
        ColoredBox(
          color: const Color(0xFF1A6B3C),
          child: TabBar(
            controller: _tabController,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: _tabPhases
                .map((p) => Tab(text: BracketData.phaseLabels[p]))
                .toList(),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: _tabPhases.map((phase) {
              final matches = phase == 'final'
                  ? [
                      ..._resolved.where((r) => r.def.phase == 'final'),
                      ..._resolved.where((r) => r.def.phase == '3rd'),
                    ]
                  : _resolved.where((r) => r.def.phase == phase).toList();

              return _PhaseTab(
                matches: matches,
                teams: widget.teams,
                cup: widget.cup,
                officialMatches: widget.knockoutMatchesById,
                savedPredictions: _koPreds,
                localPalpites: _localPalpites,
                localWinners: _localWinners,
                localScoreSet: _localScoreSet,
                saving: _saving,
                savingAll: _savingAll,
                onIncrement: _incrementar,
                onDecrement: _decrementar,
                onSave: _salvar,
                onSaveAll: () => _salvarTodos(matches),
                onSelectWinner: _selecionarVencedor,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// ─── Aba de uma fase ──────────────────────────────────────────────────────────

class _PhaseTab extends StatelessWidget {
  final List<ResolvedMatch> matches;
  final Map<String, Team> teams;
  final Cup cup;
  final Map<String, Match> officialMatches;
  final Map<String, KnockoutPrediction> savedPredictions;
  final Map<String, List<int>> localPalpites;
  final Map<String, String?> localWinners;
  final Set<String> localScoreSet;
  final Map<String, bool> saving;
  final bool savingAll;
  final void Function(String slotId, int side) onIncrement;
  final void Function(String slotId, int side) onDecrement;
  final Future<void> Function(ResolvedMatch) onSave;
  final Future<void> Function() onSaveAll;
  final void Function(String slotId, String teamId) onSelectWinner;

  const _PhaseTab({
    required this.matches,
    required this.teams,
    required this.cup,
    required this.officialMatches,
    required this.savedPredictions,
    required this.localPalpites,
    required this.localWinners,
    required this.localScoreSet,
    required this.saving,
    required this.savingAll,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSave,
    required this.onSaveAll,
    required this.onSelectWinner,
  });

  @override
  Widget build(BuildContext context) {
    final allPending = matches.every((r) => !r.canPredict);

    return Column(
      children: [
        if (cup.isLocked)
          Container(
            width: double.infinity,
            color: Colors.orange.withValues(alpha: 0.1),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.orange, size: 16),
                SizedBox(width: 8),
                Text('Palpites encerrados',
                    style: TextStyle(color: Colors.orange)),
              ],
            ),
          )
        else if (allPending)
          Container(
            width: double.infinity,
            color: Colors.blue.withValues(alpha: 0.08),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Complete os palpites da fase anterior para liberar esta fase',
                    style: TextStyle(color: Colors.blue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
            itemCount: matches.length,
            itemBuilder: (context, i) {
              final rm = matches[i];
              return BracketMatchCard(
                resolved: rm,
                teams: teams,
                officialMatch: officialMatches[rm.def.id],
                savedPrediction: savedPredictions[rm.def.id],
                locked: cup.isLocked,
                palpite: localPalpites[rm.def.id] ?? [0, 0],
                scoreIsSet: localScoreSet.contains(rm.def.id),
                selectedWinner: localWinners[rm.def.id],
                isSaving: saving[rm.def.id] ?? false,
                onIncrement: (side) => onIncrement(rm.def.id, side),
                onDecrement: (side) => onDecrement(rm.def.id, side),
                onSave: () => onSave(rm),
                onSelectWinner: (teamId) => onSelectWinner(rm.def.id, teamId),
              );
            },
          ),
        ),
        if (!cup.isLocked && !allPending)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B3C),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: savingAll ? null : onSaveAll,
                  icon: savingAll
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Salvar todos os palpites',
                      style: TextStyle(fontSize: 15)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
