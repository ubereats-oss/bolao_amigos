import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/extra_question.dart';
import '../../data/repositories/extra_prediction_repository.dart';
import '../../data/models/team.dart';
import '../../data/models/player.dart';
import '../../services/firestore_service.dart';
import '../extras/widgets/team_selection_sheet.dart';
import '../extras/widgets/player_selection_sheet.dart';
class ManageExtraQuestionsScreen extends StatefulWidget {
  const ManageExtraQuestionsScreen({super.key});
  @override
  State<ManageExtraQuestionsScreen> createState() =>
      _ManageExtraQuestionsScreenState();
}
class _ManageExtraQuestionsScreenState
    extends State<ManageExtraQuestionsScreen> {
  final _repo = ExtraPredictionRepository();
  final _firestoreService = FirestoreService();
  final _db = FirebaseFirestore.instance;
  List<ExtraQuestion> _questions = [];
  List<Team> _teams = [];
  List<Player> _players = [];
  String? _cupId;
  bool _loading = true;
  String? _erro;
  @override
  void initState() {
    super.initState();
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
      final results = await Future.wait([
        _repo.fetchQuestions(cup.id),
        _repo.fetchTeams(cup.id),
        _repo.fetchPlayers(cup.id),
      ]);
      setState(() {
        _questions = results[0] as List<ExtraQuestion>;
        _teams = results[1] as List<Team>;
        _players = results[2] as List<Player>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _erro = 'Erro ao carregar perguntas.';
        _loading = false;
      });
    }
  }
  Future<void> _abrirFormulario({ExtraQuestion? question}) async {
    final textCtrl =
        TextEditingController(text: question?.question ?? '');
    ExtraQuestionType tipo = question?.type ?? ExtraQuestionType.team;
    String? correctAnswer = question?.correctAnswer;
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> selecionarGabarito() async {
              final result = await _selecionarGabarito(
                tipo: tipo,
                selectedId: correctAnswer,
              );
              if (result != null) {
                setDialogState(() => correctAnswer = result);
              }
            }

            return AlertDialog(
              title: Text(
                  question == null ? 'Nova Pergunta' : 'Editar Pergunta'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: textCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Pergunta',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Tipo de resposta:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    RadioGroup<ExtraQuestionType>(
                      groupValue: tipo,
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            tipo = v;
                            correctAnswer = null;
                          });
                        }
                      },
                      child: const Column(
                        children: [
                          RadioListTile<ExtraQuestionType>(
                            title: Text('Seleção (time)'),
                            value: ExtraQuestionType.team,
                          ),
                          RadioListTile<ExtraQuestionType>(
                            title: Text('Jogador'),
                            value: ExtraQuestionType.player,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Gabarito:',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: selecionarGabarito,
                        icon: const Icon(Icons.fact_check_outlined),
                        label: Text(_gabaritoLabel(tipo, correctAnswer)),
                      ),
                    ),
                    if (correctAnswer != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () => setDialogState(() {
                          correctAnswer = null;
                        }),
                        icon: const Icon(Icons.clear_outlined),
                        label: const Text('Limpar gabarito'),
                      ),
                    ],
                  ],
                ),
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
                    if (textCtrl.text.trim().isEmpty) return;
                    await _salvar(
                      id: question?.id,
                      text: textCtrl.text.trim(),
                      type: tipo,
                      order: question?.order ?? (_questions.length + 1),
                      correctAnswer: correctAnswer,
                    );
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
    textCtrl.dispose();
  }
  Future<void> _salvar({
    String? id,
    required String text,
    required ExtraQuestionType type,
    required int order,
    required String? correctAnswer,
  }) async {
    if (_cupId == null) return;
    final ref = _db
        .collection('cups')
        .doc(_cupId)
        .collection('extra_questions');
    final data = {
      'question': text,
      'type': type == ExtraQuestionType.team ? 'team' : 'player',
      'order': order,
      'correct_answer': correctAnswer,
    };
    if (id == null) {
      await ref.add(data);
    } else {
      await ref.doc(id).set(data, SetOptions(merge: true));
    }
    await _carregar();
  }

  Future<String?> _selecionarGabarito({
    required ExtraQuestionType tipo,
    required String? selectedId,
  }) async {
    if (tipo == ExtraQuestionType.team) {
      if (_teams.isEmpty) return null;
      return showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        builder: (_) => TeamSelectionSheet(
          title: 'Selecionar gabarito',
          teams: _teams,
          selectedId: selectedId,
          teamsExcluidos: const {},
        ),
      );
    }
    if (_players.isEmpty) return null;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => PlayerSelectionSheet(
        title: 'Selecionar gabarito',
        teams: _teams,
        players: _players,
        selectedPlayerId: selectedId,
      ),
    );
  }

  String _gabaritoLabel(ExtraQuestionType tipo, String? id) {
    if (id == null || id.isEmpty) return 'Selecionar gabarito';
    if (tipo == ExtraQuestionType.team) {
      final team = _teams.firstWhere(
        (t) => t.id == id,
        orElse: () => const Team(id: '', name: 'Desconhecido', flagAsset: ''),
      );
      return team.name;
    }
    final player = _players.firstWhere(
      (p) => p.id == id,
      orElse: () => const Player(id: '', name: 'Desconhecido', teamId: '', position: ''),
    );
    final team = _teams.firstWhere(
      (t) => t.id == player.teamId,
      orElse: () => const Team(id: '', name: '', flagAsset: ''),
    );
    return team.name.isNotEmpty ? '${player.name} (${team.name})' : player.name;
  }
  Future<void> _excluir(ExtraQuestion question) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Excluir pergunta?'),
        content: Text(question.question),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmar == true && _cupId != null) {
      await _db
          .collection('cups')
          .doc(_cupId)
          .collection('extra_questions')
          .doc(question.id)
          .delete();
      await _carregar();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perguntas Extras'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
        onPressed: () => _abrirFormulario(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _erro != null
              ? Center(child: Text(_erro!))
              : _questions.isEmpty
                  ? const Center(child: Text('Nenhuma pergunta cadastrada.'))
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _questions.length,
                      itemBuilder: (context, index) {
                        final q = _questions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: Icon(
                              q.type == ExtraQuestionType.team
                                  ? Icons.flag_outlined
                                  : Icons.person_outline,
                              color: const Color(0xFF1A6B3C),
                            ),
                            title: Text(q.question),
                            subtitle: Text(
                              'Resposta: ${q.type == ExtraQuestionType.team ? 'Seleção' : 'Jogador'}'
                              ' · Gabarito: ${_gabaritoLabel(q.type, q.correctAnswer)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  onPressed: () =>
                                      _abrirFormulario(question: q),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () => _excluir(q),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
