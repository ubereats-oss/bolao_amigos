import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/models/extra_question.dart';
import '../../data/models/extra_prediction.dart';
import '../../data/models/team.dart';
import '../../data/models/player.dart';
import '../../data/repositories/extra_prediction_repository.dart';
import '../../data/repositories/group_repository.dart';
import '../../data/repositories/match_repository.dart';
import '../../data/repositories/knockout_prediction_repository.dart';
import '../../services/firestore_service.dart';
import '../matches/bracket_engine.dart';
import 'widgets/question_card.dart';

class ExtraPredictionsScreen extends StatefulWidget {
  final String groupId;

  const ExtraPredictionsScreen({super.key, required this.groupId});

  @override
  State<ExtraPredictionsScreen> createState() =>
      _ExtraPredictionsScreenState();
}

class _ExtraPredictionsScreenState extends State<ExtraPredictionsScreen> {
  final _extraRepo = ExtraPredictionRepository();
  final _matchRepo = MatchRepository();
  final _koRepo = KnockoutPredictionRepository();
  final _firestoreService = FirestoreService();
  late final GroupRepository _groupRepo;

  List<ExtraQuestion> _questions = [];
  Map<String, ExtraPrediction> _predictions = {};
  List<Team> _teams = [];
  List<Player> _players = [];
  bool _locked = false;
  bool _loading = true;
  String? _erro;
  String? _cupId;

  // order → teamId (para as perguntas auto-preenchíveis)
  Map<int, String?> _autoFill = {};

  @override
  void initState() {
    super.initState();
    _groupRepo = GroupRepository();
    _carregar();
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
      _cupId = cup.id;
      _locked = cup.isLocked;
      final uid = FirebaseAuth.instance.currentUser!.uid;

      final results = await Future.wait([
        _extraRepo.fetchQuestions(cup.id),
        _groupRepo.fetchAllExtraPredictions(widget.groupId, uid),
        _extraRepo.fetchTeams(cup.id),
        _extraRepo.fetchPlayers(cup.id),
        _matchRepo.fetchGroupMatches(cup.id),
        _groupRepo.fetchAllPredictions(widget.groupId, uid),
        _koRepo.fetchAll(widget.groupId, uid),
      ]);

      final groupMatches = results[4] as dynamic;
      final rawGroupPreds = results[5] as dynamic;
      final koPreds = results[6] as dynamic;

      // Converte Prediction → List<int>?
      final groupPredictions = <String, List<int>?>{};
      for (final entry in (rawGroupPreds as Map).entries) {
        final p = entry.value;
        groupPredictions[entry.key as String] = [p.homeGoals as int, p.awayGoals as int];
      }

      setState(() {
        _questions = results[0] as List<ExtraQuestion>;
        _predictions = results[1] as Map<String, ExtraPrediction>;
        _teams = results[2] as List<Team>;
        _players = results[3] as List<Player>;
        _autoFill = _computeAutoFill(
          groupMatches: groupMatches as dynamic,
          groupPredictions: groupPredictions,
          koPreds: koPreds as dynamic,
        );
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar perguntas.';
        _loading = false;
      });
    }
  }

  Map<int, String?> _computeAutoFill({
    required dynamic groupMatches,
    required Map<String, List<int>?> groupPredictions,
    required dynamic koPreds,
  }) {
    final engine = BracketEngine(
      groupMatches: groupMatches,
      groupPredictions: groupPredictions,
      knockoutPredictions: koPreds,
      groupTeams: {},
    );

    final standings = engine.computeStandings();
    final result = <int, String?>{};

    // Coleta todos os times com pelo menos 1 jogo previsto
    final allTeams = <dynamic>[];
    for (final gs in standings.values) {
      for (final ts in gs.standings) {
        if (ts.gamesPlayed > 0) allTeams.add(ts);
      }
    }

    if (allTeams.isNotEmpty) {
      // Melhor campanha: mais pontos > saldo > gols pró
      final best = allTeams.reduce((a, b) {
        if (b.points != a.points) return b.points > a.points ? b : a;
        if (b.goalDiff != a.goalDiff) return b.goalDiff > a.goalDiff ? b : a;
        return b.goalsFor > a.goalsFor ? b : a;
      });
      // Pior campanha: menos pontos > pior saldo > menos gols pró
      final worst = allTeams.reduce((a, b) {
        if (a.points != b.points) return a.points < b.points ? a : b;
        if (a.goalDiff != b.goalDiff) return a.goalDiff < b.goalDiff ? a : b;
        return a.goalsFor < b.goalsFor ? a : b;
      });
      // Melhor ataque: mais gols marcados
      final bestAtk = allTeams.reduce((a, b) => b.goalsFor > a.goalsFor ? b : a);
      // Pior ataque: menos gols marcados
      final worstAtk = allTeams.reduce((a, b) => a.goalsFor < b.goalsFor ? a : b);

      result[6] = (best as dynamic).teamId as String;
      result[7] = (worst as dynamic).teamId as String;
      result[8] = (bestAtk as dynamic).teamId as String;
      result[9] = (worstAtk as dynamic).teamId as String;
    }

    // Campeão e Vice: baseados no mata-mata
    final resolved = engine.resolveAll();
    ResolvedMatch? finalMatch;
    for (final r in resolved) {
      if (r.def.phase == 'final') {
        finalMatch = r;
        break;
      }
    }
    if (finalMatch != null &&
        finalMatch.homeTeamId != null &&
        finalMatch.awayTeamId != null) {
      final pred = (koPreds as Map)[finalMatch.def.id];
      if (pred != null) {
        String champion;
        if (pred.winner != null) {
          champion = pred.winner as String;
        } else if (pred.homeGoals != null && pred.awayGoals != null) {
          champion = (pred.homeGoals as int) >= (pred.awayGoals as int)
              ? finalMatch.homeTeamId!
              : finalMatch.awayTeamId!;
        } else {
          champion = finalMatch.homeTeamId!;
        }
        final vice = champion == finalMatch.homeTeamId
            ? finalMatch.awayTeamId
            : finalMatch.homeTeamId;
        result[1] = champion;
        result[2] = vice;
      }
    }

    return result;
  }

  Future<void> _salvar(String questionId, String answer) async {
    if (_locked || _cupId == null) return;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final prediction = ExtraPrediction(
      questionId: questionId,
      userId: uid,
      answer: answer,
      savedAt: DateTime.now(),
    );
    await _groupRepo.saveExtraPrediction(widget.groupId, prediction);
    setState(() => _predictions[questionId] = prediction);
  }

  Set<String> _teamsJaEscolhidos(String questionIdAtual) {
    final Set<String> usados = {};
    for (final q in _questions) {
      if (q.type == ExtraQuestionType.team && q.id != questionIdAtual) {
        final pred = _predictions[q.id];
        if (pred != null && pred.answer.isNotEmpty) usados.add(pred.answer);
      }
    }
    return usados;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palpites Extras'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_questions.isEmpty) {
      return const Center(child: Text('Nenhuma pergunta disponível.'));
    }
    return Column(
      children: [
        if (_locked)
          Container(
            width: double.infinity,
            color: Colors.orange.withValues(alpha: 0.1),
            padding:
                const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Colors.orange, size: 18),
                SizedBox(width: 8),
                Text('A Copa já começou. Palpites encerrados.',
                    style: TextStyle(color: Colors.orange)),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _questions.length,
            itemBuilder: (context, index) {
              final question = _questions[index];
              final autoFillTeamId = _autoFill[question.order];
              return QuestionCard(
                question: question,
                prediction: _predictions[question.id],
                teams: _teams,
                players: _players,
                locked: _locked,
                teamsExcluidos: question.type == ExtraQuestionType.team
                    ? _teamsJaEscolhidos(question.id)
                    : {},
                autoFillTeamId: autoFillTeamId,
                onSave: (answer) => _salvar(question.id, answer),
                onAutoFill: autoFillTeamId != null && !_locked
                    ? () => _salvar(question.id, autoFillTeamId)
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }
}
