import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/models/cup.dart';
import '../../data/models/prediction.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../services/firestore_service.dart';
import 'knockout_bracket_screen.dart';
import 'widgets/match_list_tab.dart';

class MatchesScreen extends StatefulWidget {
  final String groupId;

  const MatchesScreen({super.key, required this.groupId});

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen>
    with SingleTickerProviderStateMixin {
  final _matchRepo = MatchRepository();
  final _firestoreService = FirestoreService();
  late final GroupRepository _groupRepo;

  late TabController _tabController;

  List<Match> _groupMatches = [];
  Map<String, Match> _knockoutMatchesById = {};
  Map<String, Team> _teams = {};
  Cup? _cup;

  // null = sem palpite salvo; List<int> = palpite salvo pelo usuário
  final Map<String, List<int>?> _palpites = {};
  final Map<String, bool> _saving = {};
  bool _savingAll = false;
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _groupRepo = GroupRepository();
    _tabController = TabController(length: 2, vsync: this);
    _carregar();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _carregar() async {
    try {
      final cup = await _firestoreService.fetchActiveCup();
      if (cup == null) {
        setState(() {
          _erro = 'Nenhum bolão ativo encontrado.';
          _loading = false;
        });
        return;
      }
      _cup = cup;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final results = await Future.wait([
        _matchRepo.fetchGroupMatches(cup.id),
        _matchRepo.fetchKnockoutMatches(cup.id),
        _matchRepo.fetchTeams(cup.id),
        _groupRepo.fetchAllPredictions(widget.groupId, uid),
      ]);

      final groupMatches = results[0] as List<Match>;
      final knockoutMatches = results[1] as List<Match>;
      final teams = results[2] as Map<String, Team>;
      final predictions = results[3] as Map<String, Prediction>;

      // Inicializa todos como null (sem palpite)
      final Map<String, List<int>?> palpites = {
        for (final m in groupMatches) m.id: null,
      };
      // Sobrescreve apenas os que têm palpite salvo
      for (final entry in predictions.entries) {
        palpites[entry.key] = [entry.value.homeGoals, entry.value.awayGoals];
      }

      setState(() {
        _groupMatches = groupMatches;
        _knockoutMatchesById = {
          for (final match in knockoutMatches) match.id: match,
        };
        _teams = teams;
        _palpites.addAll(palpites);
        _loading = false;
      });
    } catch (e) {
      debugPrint('_carregar: $e');
      setState(() {
        _erro = 'Erro ao carregar jogos.';
        _loading = false;
      });
    }
  }

  void _incrementar(String matchId, int side) {
    if (_cup?.isLocked ?? true) return;
    setState(() {
      final atual = _palpites[matchId] ?? [0, 0];
      final novo = List<int>.from(atual);
      novo[side] = (novo[side] + 1).clamp(0, 99);
      _palpites[matchId] = novo;
    });
  }

  void _decrementar(String matchId, int side) {
    if (_cup?.isLocked ?? true) return;
    setState(() {
      final atual = _palpites[matchId] ?? [0, 0];
      final novo = List<int>.from(atual);
      novo[side] = (novo[side] - 1).clamp(0, 99);
      _palpites[matchId] = novo;
    });
  }

  Future<void> _salvarUm(Match match) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _saving[match.id] = true);
    try {
      final gols = _palpites[match.id] ?? [0, 0];
      await _groupRepo.savePrediction(
        widget.groupId,
        Prediction(
          matchId: match.id,
          userId: uid,
          homeGoals: gols[0],
          awayGoals: gols[1],
          savedAt: DateTime.now(),
        ),
      );
      setState(() => _palpites[match.id] = gols);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Palpite salvo!'),
          duration: Duration(seconds: 1),
          backgroundColor: Color(0xFF1A6B3C),
        ));
      }
    } catch (e) {
      debugPrint('_salvarUm: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao salvar palpite.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving[match.id] = false);
    }
  }

  Future<void> _salvarTodos() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _savingAll = true);
    try {
      int count = 0;
      for (final match in _groupMatches) {
        final gols = _palpites[match.id];
        if (gols == null) continue; // sem palpite: não salva
        await _groupRepo.savePrediction(
          widget.groupId,
          Prediction(
            matchId: match.id,
            userId: uid,
            homeGoals: gols[0],
            awayGoals: gols[1],
            savedAt: DateTime.now(),
          ),
        );
        count++;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$count palpites salvos!'),
          backgroundColor: const Color(0xFF1A6B3C),
        ));
      }
    } catch (e) {
      debugPrint('_salvarTodos: $e');
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

  Future<void> _apagarTodos() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar todos os palpites'),
        content: const Text(
            'Todos os seus palpites da fase de grupos serão removidos. Deseja continuar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    setState(() => _savingAll = true);
    try {
      await _groupRepo.deleteAllPredictions(widget.groupId, uid);
      setState(() {
        for (final key in _palpites.keys.toList()) {
          _palpites[key] = null;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Palpites apagados.'),
          backgroundColor: Color(0xFF1A6B3C),
        ));
      }
    } catch (e) {
      debugPrint('_apagarTodos: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Erro ao apagar palpites.'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _savingAll = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Palpites'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        actions: [
          if (!_loading && _erro == null && (_cup?.isLocked == false))
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Apagar todos os palpites',
              onPressed: _savingAll ? null : _apagarTodos,
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Fase de Grupos'),
            Tab(text: 'Mata-Mata'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    MatchListTab(
                      matches: _groupMatches,
                      teams: _teams,
                      cup: _cup!,
                      palpites: _palpites,
                      saving: _saving,
                      savingAll: _savingAll,
                      onIncrement: _incrementar,
                      onDecrement: _decrementar,
                      onSaveOne: _salvarUm,
                      onSaveAll: _salvarTodos,
                    ),
                    KnockoutBracketScreen(
                      groupId: widget.groupId,
                      cup: _cup!,
                      groupMatches: _groupMatches,
                      groupPredictions: _palpites,
                      knockoutMatchesById: _knockoutMatchesById,
                      teams: _teams,
                    ),
                  ],
                ),
    );
  }
}
