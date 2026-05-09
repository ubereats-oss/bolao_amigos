import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../data/models/match.dart';
import '../../../data/models/team.dart';
import '../../../services/scoring_rules.dart';
import 'points_badge.dart';
import 'team_block.dart';
import 'score_control.dart';

class MatchCard extends StatelessWidget {
  final Match match;
  final Team? home;
  final Team? away;
  // null = sem palpite salvo; List<int> = [homeGoals, awayGoals]
  final List<int>? palpite;
  final bool locked;
  final bool isSaving;
  final void Function(int side) onIncrement;
  final void Function(int side) onDecrement;
  final VoidCallback onSave;

  const MatchCard({
    super.key,
    required this.match,
    required this.home,
    required this.away,
    required this.palpite,
    required this.locked,
    required this.isSaving,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy · HH:mm').format(match.matchTime);
    final temPalpite = palpite != null;
    final pontos = match.finished && match.groupId != null
        ? temPalpite
            ? ScoringRules.matchPoints(
                officialHomeGoals: match.officialHomeGoals ?? 0,
                officialAwayGoals: match.officialAwayGoals ?? 0,
                predictedHomeGoals: palpite![0],
                predictedAwayGoals: palpite![1],
              )
            : 0
        : null;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(dateStr,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: TeamBlock(team: home)),
                (temPalpite || !locked)
                    ? ScoreControl(
                        homeGoals: palpite?[0],
                        awayGoals: palpite?[1],
                        locked: locked,
                        onIncrementHome: () => onIncrement(0),
                        onDecrementHome: () => onDecrement(0),
                        onIncrementAway: () => onIncrement(1),
                        onDecrementAway: () => onDecrement(1),
                      )
                    : const _SemPalpiteDisplay(locked: true),
                Expanded(child: TeamBlock(team: away, alignRight: true)),
              ],
            ),
            const SizedBox(height: 10),
            if (match.finished)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Resultado oficial: '
                      '${match.officialHomeGoals} × ${match.officialAwayGoals}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6B3C),
                          fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PointsBadge(points: pontos ?? 0),
                ],
              )
            else if (!locked)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isSaving ? null : onSave,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A6B3C),
                    side: const BorderSide(color: Color(0xFF1A6B3C)),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                  ),
                  child: isSaving
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF1A6B3C)),
                        )
                      : Text(temPalpite
                          ? 'Salvar este palpite'
                          : 'Fazer palpite'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Exibido quando o usuário ainda não fez palpite nesse jogo.
/// Ao tocar nos botões, o ScoreControl aparece com 0×0 e o usuário
/// pode ajustar antes de salvar.
class _SemPalpiteDisplay extends StatelessWidget {
  final bool locked;

  const _SemPalpiteDisplay({required this.locked});

  @override
  Widget build(BuildContext context) {
    if (locked) {
      // Copa encerrada e sem palpite: exibe traço fixo
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '— × —',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
            letterSpacing: 2,
          ),
        ),
      );
    }
    // Ainda aberto: exibe traço indicando que falta palpitar
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '— × —',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 2,
            ),
          ),
          SizedBox(height: 2),
          Text(
            'sem palpite',
            style: TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
