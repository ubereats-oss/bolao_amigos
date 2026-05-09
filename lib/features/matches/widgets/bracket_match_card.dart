import 'package:flutter/material.dart';
import '../../../core/constants/bracket_data.dart';
import '../../../data/models/knockout_prediction.dart';
import '../../../data/models/match.dart';
import '../../../data/models/team.dart';
import '../../matches/bracket_engine.dart';
import '../../../services/scoring_rules.dart';
import 'points_badge.dart';
import '../widgets/score_control.dart';
import '../widgets/team_block.dart';

class BracketMatchCard extends StatelessWidget {
  final ResolvedMatch resolved;
  final Map<String, Team> teams;
  final Match? officialMatch;
  final KnockoutPrediction? savedPrediction;
  final bool locked;
  final List<int> palpite;
  final bool isSaving;
  final void Function(int side) onIncrement;
  final void Function(int side) onDecrement;
  final VoidCallback onSave;

  const BracketMatchCard({
    super.key,
    required this.resolved,
    required this.teams,
    required this.officialMatch,
    required this.savedPrediction,
    required this.locked,
    required this.palpite,
    required this.isSaving,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final home =
        resolved.homeTeamId != null ? teams[resolved.homeTeamId] : null;
    final away =
        resolved.awayTeamId != null ? teams[resolved.awayTeamId] : null;
    final phaseLabel = BracketData.phaseLabels[resolved.def.phase] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _buildCard(home, away, phaseLabel),
      ),
    );
  }

  Widget _buildCard(Team? home, Team? away, String phaseLabel) {
    final homeLabel = home?.name ?? resolved.homeSlotLabel;
    final awayLabel = away?.name ?? resolved.awaySlotLabel;
    final officialFinished = officialMatch?.finished ?? false;
    final hasSavedPrediction = savedPrediction != null;
    final pontos = officialFinished && officialMatch?.groupId != null
        ? hasSavedPrediction
            ? ScoringRules.matchPoints(
                officialHomeGoals: officialMatch?.officialHomeGoals ?? 0,
                officialAwayGoals: officialMatch?.officialAwayGoals ?? 0,
                predictedHomeGoals: savedPrediction!.homeGoals,
                predictedAwayGoals: savedPrediction!.awayGoals,
              )
            : 0
        : null;
    final displayPalpite = hasSavedPrediction
        ? [savedPrediction!.homeGoals, savedPrediction!.awayGoals]
        : palpite;
    final controlLocked = locked || officialFinished || !resolved.canPredict;
    final canSave = !locked && !officialFinished && resolved.canPredict;
    final scoreWidget = officialFinished && !hasSavedPrediction
        ? const Padding(
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
          )
        : ScoreControl(
            homeGoals: displayPalpite[0],
            awayGoals: displayPalpite[1],
            locked: controlLocked,
            onIncrementHome: () => onIncrement(0),
            onDecrementHome: () => onDecrement(0),
            onIncrementAway: () => onIncrement(1),
            onDecrementAway: () => onDecrement(1),
          );

    return Column(
      children: [
        Text(phaseLabel,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TeamBlock(
                team: home,
                fallbackLabel: homeLabel,
              ),
            ),
            scoreWidget,
            Expanded(
              child: TeamBlock(
                team: away,
                alignRight: true,
                fallbackLabel: awayLabel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (officialFinished)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  'Resultado oficial: '
                  '${officialMatch?.officialHomeGoals} × ${officialMatch?.officialAwayGoals}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A6B3C),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PointsBadge(points: pontos ?? 0),
            ],
          )
        else if (canSave)
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
                  : const Text('Salvar palpite'),
            ),
          )
        else if (!resolved.canPredict && !locked)
          const Text(
            'Complete os palpites da fase anterior',
            style: TextStyle(fontSize: 12, color: Colors.orange),
          ),
      ],
    );
  }
}
