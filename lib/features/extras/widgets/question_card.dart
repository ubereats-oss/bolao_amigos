import 'package:flutter/material.dart';
import '../../../data/models/extra_question.dart';
import '../../../data/models/extra_prediction.dart';
import '../../../data/models/team.dart';
import '../../../data/models/player.dart';
import 'team_selection_sheet.dart';
import 'player_selection_sheet.dart';

class QuestionCard extends StatelessWidget {
  final ExtraQuestion question;
  final ExtraPrediction? prediction;
  final List<Team> teams;
  final List<Player> players;
  final bool locked;
  final Set<String> teamsExcluidos;
  final String? autoFillTeamId;
  final VoidCallback? onAutoFill;
  final Future<void> Function(String answer) onSave;

  const QuestionCard({
    super.key,
    required this.question,
    required this.prediction,
    required this.teams,
    required this.players,
    required this.locked,
    required this.teamsExcluidos,
    this.autoFillTeamId,
    this.onAutoFill,
    required this.onSave,
  });

  Future<void> _abrirSelecao(BuildContext context) async {
    if (locked) return;
    if (question.type == ExtraQuestionType.team) {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => TeamSelectionSheet(
          title: question.question,
          teams: teams,
          selectedId: prediction?.answer,
          teamsExcluidos: teamsExcluidos,
        ),
      );
      if (result != null) await onSave(result);
    } else {
      final result = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => PlayerSelectionSheet(
          title: question.question,
          teams: teams,
          players: question.positionFilter != null
              ? players
                  .where((p) => p.position == question.positionFilter)
                  .toList()
              : players,
          selectedPlayerId: prediction?.answer,
          lockedTeamId: question.teamFilter,
        ),
      );
      if (result != null) await onSave(result);
    }
  }

  String _labelResposta() {
    if (prediction == null || prediction!.answer.isEmpty) {
      return 'Toque para responder';
    }
    if (question.type == ExtraQuestionType.team) {
      return teams
          .firstWhere((t) => t.id == prediction!.answer,
              orElse: () =>
                  const Team(id: '', name: 'Desconhecido', flagAsset: ''))
          .name;
    }
    final player = players.firstWhere(
      (p) => p.id == prediction!.answer,
      orElse: () =>
          const Player(id: '', name: 'Desconhecido', teamId: '', position: ''),
    );
    final team = teams.firstWhere(
      (t) => t.id == player.teamId,
      orElse: () => const Team(id: '', name: '', flagAsset: ''),
    );
    return team.name.isNotEmpty ? '${player.name} (${team.name})' : player.name;
  }

  Widget _leading() {
    if (prediction == null || prediction!.answer.isEmpty) {
      return const Icon(Icons.help_outline, size: 32, color: Colors.grey);
    }
    String? flagAsset;
    if (question.type == ExtraQuestionType.team) {
      flagAsset = teams
          .firstWhere((t) => t.id == prediction!.answer,
              orElse: () => const Team(id: '', name: '', flagAsset: ''))
          .flagAsset;
    } else {
      final player = players.firstWhere(
        (p) => p.id == prediction!.answer,
        orElse: () => const Player(id: '', name: '', teamId: '', position: ''),
      );
      flagAsset = teams
          .firstWhere((t) => t.id == player.teamId,
              orElse: () => const Team(id: '', name: '', flagAsset: ''))
          .flagAsset;
    }
    if (flagAsset.isEmpty) {
      return Icon(
        question.type == ExtraQuestionType.team
            ? Icons.flag_outlined
            : Icons.person_outline,
        size: 32,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.asset(flagAsset,
          width: 48,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.flag_outlined, size: 32)),
    );
  }

  Widget? _autoFillButton() {
    if (onAutoFill == null || autoFillTeamId == null || locked) return null;
    final team = teams.firstWhere(
      (t) => t.id == autoFillTeamId,
      orElse: () => const Team(id: '', name: '', flagAsset: ''),
    );
    if (team.id.isEmpty) return null;

    return InkWell(
      onTap: onAutoFill,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        margin: const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A6B3C).withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFF1A6B3C).withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_fix_high_outlined,
                size: 14, color: Color(0xFF1A6B3C)),
            const SizedBox(width: 6),
            const Text(
              'Preencher com ',
              style: TextStyle(fontSize: 12, color: Color(0xFF1A6B3C)),
            ),
            if (team.flagAsset.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.asset(
                  team.flagAsset,
                  width: 18,
                  height: 12,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              team.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A6B3C),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final respondido = prediction != null && prediction!.answer.isNotEmpty;
    final autoFillBtn = _autoFillButton();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: _leading(),
            title: Text(question.question,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              _labelResposta(),
              style: TextStyle(
                  color: respondido ? const Color(0xFF1A6B3C) : Colors.grey),
            ),
            trailing: locked
                ? const Icon(Icons.lock_outline, color: Colors.orange)
                : const Icon(Icons.chevron_right),
            onTap: locked ? null : () => _abrirSelecao(context),
          ),
          if (autoFillBtn != null) autoFillBtn,
        ],
      ),
    );
  }
}
