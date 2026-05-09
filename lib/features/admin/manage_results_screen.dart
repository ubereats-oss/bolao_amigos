import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/repositories/match_repository.dart';
import '../../services/firestore_service.dart';

class ManageResultsScreen extends StatefulWidget {
  final String groupId;

  const ManageResultsScreen({super.key, required this.groupId});

  @override
  State<ManageResultsScreen> createState() => _ManageResultsScreenState();
}

class _ManageResultsScreenState extends State<ManageResultsScreen> {
  final _matchRepo = MatchRepository();
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;

  List<Match> _matches = [];
  Map<String, Team> _teams = {};
  String? _cupId;
  bool _loading = true;
  bool _salvando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar({bool forceRefresh = false}) async {
    try {
      final cup =
          await _firestoreService.fetchActiveCup(forceRefresh: forceRefresh);
      if (cup == null) {
        setState(() {
          _erro = 'Nenhum bolão ativo encontrado.';
          _loading = false;
        });
        return;
      }
      _cupId = cup.id;
      final results = await Future.wait([
        _matchRepo.fetchGroupMatches(cup.id, forceRefresh: forceRefresh),
        _matchRepo.fetchKnockoutMatches(cup.id, forceRefresh: forceRefresh),
        _matchRepo.fetchTeams(cup.id, forceRefresh: forceRefresh),
      ]);
      final group = results[0] as List<Match>;
      final knockout = results[1] as List<Match>;
      setState(() {
        _matches = [...group, ...knockout]
          ..sort((a, b) => a.matchTime.compareTo(b.matchTime));
        _teams = results[2] as Map<String, Team>;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _erro = 'Erro ao carregar jogos.';
        _loading = false;
      });
    }
  }

  Future<void> _salvarResultado(Match match, int home, int away) async {
    if (_cupId == null) return;
    setState(() => _salvando = true);
    final collection = match.groupId != null
        ? _db
            .collection('cups')
            .doc(_cupId)
            .collection('groups')
            .doc(match.groupId)
            .collection('matches')
        : _db.collection('cups').doc(_cupId).collection('knockout_matches');
    try {
      await collection.doc(match.id).set({
        'official_home_goals': home,
        'official_away_goals': away,
        'finished': true,
      }, SetOptions(merge: true));
      MatchRepository.clearCache();
      await _carregar(forceRefresh: true);
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  Future<void> _abrirEdicao(Match match) async {
    final homeCtrl =
        TextEditingController(text: match.officialHomeGoals?.toString() ?? '');
    final awayCtrl =
        TextEditingController(text: match.officialAwayGoals?.toString() ?? '');
    String? erroDialog;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            '${_teams[match.homeTeamId]?.name ?? match.homeTeamId} × '
            '${_teams[match.awayTeamId]?.name ?? match.awayTeamId}',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: homeCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('×',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: 60,
                    child: TextField(
                      controller: awayCtrl,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                      decoration:
                          const InputDecoration(border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              if (erroDialog != null) ...[
                const SizedBox(height: 8),
                Text(erroDialog!,
                    style: const TextStyle(color: Colors.red, fontSize: 13)),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6B3C)),
              onPressed: () async {
                final home = int.tryParse(homeCtrl.text.trim());
                final away = int.tryParse(awayCtrl.text.trim());
                if (home == null ||
                    away == null ||
                    home < 0 ||
                    away < 0 ||
                    home > 99 ||
                    away > 99) {
                  setDialogState(() => erroDialog =
                      'Informe placares entre 0 e 99.');
                  return;
                }
                await _salvarResultado(match, home, away);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );

    homeCtrl.dispose();
    awayCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inserir Resultados'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : Stack(
                  children: [
                    ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _matches.length,
                      itemBuilder: (context, index) {
                        final match = _matches[index];
                        final home = _teams[match.homeTeamId];
                        final away = _teams[match.awayTeamId];
                        final dateStr = DateFormat('dd/MM/yyyy · HH:mm')
                            .format(match.matchTime);
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: ListTile(
                            title: Text(
                              '${home?.name ?? match.homeTeamId} × '
                              '${away?.name ?? match.awayTeamId}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(dateStr),
                            trailing: match.finished
                                ? Text(
                                    '${match.officialHomeGoals} × '
                                    '${match.officialAwayGoals}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1A6B3C)),
                                  )
                                : const Text('Pendente',
                                    style: TextStyle(color: Colors.grey)),
                            onTap: () => _abrirEdicao(match),
                          ),
                        );
                      },
                    ),
                    if (_salvando)
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
                                  Text('Salvando resultado...'),
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
