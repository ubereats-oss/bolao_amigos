import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/models/prediction.dart';
import '../../data/models/cup.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../services/firestore_service.dart';
import '../../services/scoring_rules.dart';
import '../../core/widgets/sobre_dialog.dart';
import 'widgets/points_badge.dart';
class MatchPredictionScreen extends StatefulWidget {
  const MatchPredictionScreen({super.key});
  @override
  State<MatchPredictionScreen> createState() => _MatchPredictionScreenState();
}
class _MatchPredictionScreenState extends State<MatchPredictionScreen> {
  final _matchRepo = MatchRepository();
  final _groupRepo = GroupRepository();
  final _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  final _homeController = TextEditingController();
  final _awayController = TextEditingController();
  Match? _match;
  Prediction? _savedPrediction;
  Team? _homeTeam;
  Team? _awayTeam;
  Cup? _cup;
  bool _loading = true;
  bool _saving = false;
  bool _initialized = false;
  String? _erro;
  String? _sucesso;
  late String _cupId;
  late String _matchId;
  String? _groupId;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    _cupId = args['cupId'];
    _matchId = args['matchId'];
    _groupId = args['groupId'];
    _carregar();
  }
  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }
  Future<void> _carregar() async {
    try {
      final cup = await _firestoreService.fetchActiveCup();
      _cup = cup;
      final results = await Future.wait([
        _matchRepo.fetchMatch(_cupId, _matchId, _groupId),
        _matchRepo.fetchTeams(_cupId),
      ]);
      final match = results[0] as Match?;
      final teams = results[1] as Map<String, Team>;
      if (match == null) {
        setState(() {
          _erro = 'Jogo não encontrado.';
          _loading = false;
        });
        return;
      }
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (_groupId == null || _groupId!.isEmpty) {
        setState(() {
          _erro = 'Grupo não informado.';
          _loading = false;
        });
        return;
      }
      final prediction =
          await _groupRepo.fetchPrediction(_groupId!, uid, _matchId);
      setState(() {
        _match = match;
        _savedPrediction = prediction;
        _homeTeam = teams[match.homeTeamId];
        _awayTeam = teams[match.awayTeamId];
        _homeController.text =
            prediction != null ? prediction.homeGoals.toString() : '';
        _awayController.text =
            prediction != null ? prediction.awayGoals.toString() : '';
        _loading = false;
      });
    } catch (e) {
      debugPrint('_carregar: $e');
      setState(() {
        _erro = 'Erro ao carregar jogo.';
        _loading = false;
      });
    }
  }
  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_cup?.isLocked ?? true) return;
    setState(() {
      _saving = true;
      _erro = null;
      _sucesso = null;
    });
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final prediction = Prediction(
        matchId: _matchId,
        userId: uid,
        homeGoals: int.parse(_homeController.text),
        awayGoals: int.parse(_awayController.text),
        savedAt: DateTime.now(),
      );
      if (_groupId == null || _groupId!.isEmpty) {
        setState(() { _erro = 'Grupo não informado.'; });
        return;
      }
      await _groupRepo.savePrediction(_groupId!, prediction);
      _savedPrediction = prediction;
      setState(() { _sucesso = 'Palpite salvo com sucesso!'; });
    } catch (e) {
      debugPrint('_salvar: $e');
      setState(() { _erro = 'Erro ao salvar palpite.'; });
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Palpite'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Sobre',
            onPressed: () async => mostrarSobre(context),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null && _match == null
              ? Center(child: Text(_erro!))
              : _buildBody(),
    );
  }
  Widget _buildBody() {
    final match = _match!;
    final locked = _cup?.isLocked ?? true;
    final pontos = match.finished && match.groupId != null
        ? _savedPrediction != null
            ? ScoringRules.matchPoints(
                officialHomeGoals: match.officialHomeGoals ?? 0,
                officialAwayGoals: match.officialAwayGoals ?? 0,
                predictedHomeGoals: _savedPrediction!.homeGoals,
                predictedAwayGoals: _savedPrediction!.awayGoals,
              )
            : 0
        : null;
    final dateStr = DateFormat('dd/MM/yyyy · HH:mm').format(match.matchTime);
    final startsAt = _cup?.startsAt;
    final lockStr = startsAt != null
        ? DateFormat('dd/MM/yyyy · HH:mm').format(startsAt)
        : '';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Text(
              dateStr,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _faseLabel(match.phase),
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _TeamBlock(team: _homeTeam),
                _ScoreInput(
                  homeController: _homeController,
                  awayController: _awayController,
                  locked: locked || match.finished,
                ),
                _TeamBlock(team: _awayTeam),
              ],
            ),
            const SizedBox(height: 28),
            if (match.finished)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A6B3C).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        'Resultado oficial: '
                        '${match.officialHomeGoals} × ${match.officialAwayGoals}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                    const SizedBox(width: 8),
                    PointsBadge(points: pontos ?? 0),
                  ],
                ),
              ),
            if (locked && !match.finished)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline,
                        color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Palpites encerrados em $lockStr',
                      style: const TextStyle(color: Colors.orange),
                    ),
                  ],
                ),
              ),
            if (!locked && !match.finished)
              Text(
                'Prazo para palpitar: $lockStr',
                style: const TextStyle(color: Colors.grey, fontSize: 13),
              ),
            const SizedBox(height: 24),
            if (_sucesso != null)
              Text(_sucesso!,
                  style: const TextStyle(
                      color: Color(0xFF1A6B3C),
                      fontWeight: FontWeight.bold)),
            if (_erro != null)
              Text(_erro!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            if (!locked && !match.finished)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6B3C),
                  ),
                  onPressed: _saving ? null : _salvar,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar Palpite'),
                ),
              ),
          ],
        ),
      ),
    );
  }
  String _faseLabel(String phase) {
    switch (phase) {
      case 'group':
        return 'Fase de Grupos — Grupo ${_match?.groupId?.toUpperCase() ?? ''}';
      case 'round_of_16':
        return 'Oitavas de Final';
      case 'quarter':
        return 'Quartas de Final';
      case 'semi':
        return 'Semifinal';
      case 'final':
        return 'Final';
      default:
        return phase;
    }
  }
}
class _TeamBlock extends StatelessWidget {
  final Team? team;
  const _TeamBlock({required this.team});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              team?.flagAsset ?? '',
              width: 64,
              height: 42,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.flag_outlined, size: 42),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            team?.name ?? '?',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
class _ScoreInput extends StatelessWidget {
  final TextEditingController homeController;
  final TextEditingController awayController;
  final bool locked;
  const _ScoreInput({
    required this.homeController,
    required this.awayController,
    required this.locked,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoalField(controller: homeController, locked: locked),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Text('×',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        _GoalField(controller: awayController, locked: locked),
      ],
    );
  }
}
class _GoalField extends StatelessWidget {
  final TextEditingController controller;
  final bool locked;
  const _GoalField({
    required this.controller,
    required this.locked,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: TextFormField(
        controller: controller,
        enabled: !locked,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
            fontSize: 28, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          filled: locked,
          fillColor: Colors.grey.withValues(alpha: 0.15),
          contentPadding: const EdgeInsets.symmetric(
              vertical: 12, horizontal: 4),
        ),
        validator: (v) {
          if (v == null || v.isEmpty) return '?';
          if (int.tryParse(v) == null) return '?';
          return null;
        },
      ),
    );
  }
}
