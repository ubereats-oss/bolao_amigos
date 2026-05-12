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
  final bool scoreIsSet;
  final String? selectedWinner;
  final bool isSaving;
  final void Function(int side) onIncrement;
  final void Function(int side) onDecrement;
  final VoidCallback onSave;
  final void Function(String teamId) onSelectWinner;

  const BracketMatchCard({
    super.key,
    required this.resolved,
    required this.teams,
    required this.officialMatch,
    required this.savedPrediction,
    required this.locked,
    required this.palpite,
    required this.scoreIsSet,
    required this.selectedWinner,
    required this.isSaving,
    required this.onIncrement,
    required this.onDecrement,
    required this.onSave,
    required this.onSelectWinner,
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
    // Na Rodada de 32, mostra a colocação no grupo abaixo da bandeira
    final isR32 = resolved.def.phase == 'r32';
    final homeSubtitle =
        (isR32 && resolved.homeTeamId != null) ? resolved.homeSlotLabel : null;
    final awaySubtitle =
        (isR32 && resolved.awayTeamId != null) ? resolved.awaySlotLabel : null;
    final officialFinished = officialMatch?.finished ?? false;
    final hasSavedPrediction = savedPrediction != null;
    final pontos = officialFinished && officialMatch?.groupId != null
        ? hasSavedPrediction
            ? ScoringRules.matchPoints(
                officialHomeGoals: officialMatch?.officialHomeGoals ?? 0,
                officialAwayGoals: officialMatch?.officialAwayGoals ?? 0,
                predictedHomeGoals: savedPrediction!.homeGoals ?? 0,
                predictedAwayGoals: savedPrediction!.awayGoals ?? 0,
              )
            : 0
        : null;

    final displayPalpite = (hasSavedPrediction &&
            savedPrediction!.homeGoals != null &&
            savedPrediction!.awayGoals != null)
        ? [savedPrediction!.homeGoals!, savedPrediction!.awayGoals!]
        : palpite;

    final controlLocked = locked || officialFinished || !resolved.canPredict;
    final canSave = !locked && !officialFinished && resolved.canPredict;

    // Vencedor efetivo: derivado do placar (quando claro) ou seleção manual
    final String? effectiveWinner;
    if (scoreIsSet && palpite[0] != palpite[1]) {
      effectiveWinner =
          palpite[0] > palpite[1] ? resolved.homeTeamId : resolved.awayTeamId;
    } else {
      effectiveWinner = selectedWinner;
    }

    // Seleção manual disponível quando: pode salvar E (placar não set OU empate)
    final canManuallySelectWinner = canSave &&
        resolved.homeTeamId != null &&
        resolved.awayTeamId != null &&
        (!scoreIsSet || palpite[0] == palpite[1]);

    // Mostra linha de vencedor quando editando ou quando vencedor foi salvo
    final showWinnerRow = !officialFinished &&
        resolved.homeTeamId != null &&
        resolved.awayTeamId != null &&
        (canSave || savedPrediction?.winner != null);

    // Sem placar definido (nem salvo nem editado): passa null para exibir '—'
    final bool noScore = !scoreIsSet && savedPrediction?.homeGoals == null;
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
            homeGoals: noScore ? null : displayPalpite[0],
            awayGoals: noScore ? null : displayPalpite[1],
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
                subtitle: homeSubtitle,
              ),
            ),
            scoreWidget,
            Expanded(
              child: TeamBlock(
                team: away,
                alignRight: true,
                fallbackLabel: awayLabel,
                subtitle: awaySubtitle,
              ),
            ),
          ],
        ),
        if (showWinnerRow) ...[
          const SizedBox(height: 8),
          _WinnerRow(
            homeId: resolved.homeTeamId!,
            awayId: resolved.awayTeamId!,
            homeTeam: home,
            awayTeam: away,
            homeLabel: homeLabel,
            awayLabel: awayLabel,
            effectiveWinner: effectiveWinner,
            canSelect: canManuallySelectWinner,
            onSelect: onSelectWinner,
          ),
        ],
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

// ─── Linha de seleção de vencedor ─────────────────────────────────────────────

class _WinnerRow extends StatelessWidget {
  final String homeId;
  final String awayId;
  final Team? homeTeam;
  final Team? awayTeam;
  final String homeLabel;
  final String awayLabel;
  final String? effectiveWinner;
  final bool canSelect;
  final void Function(String teamId) onSelect;

  const _WinnerRow({
    required this.homeId,
    required this.awayId,
    this.homeTeam,
    this.awayTeam,
    required this.homeLabel,
    required this.awayLabel,
    required this.effectiveWinner,
    required this.canSelect,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('Vencedor',
            style: TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: _WinnerChip(
            label: homeLabel,
            team: homeTeam,
            isSelected: effectiveWinner == homeId,
            canSelect: canSelect,
            onTap: () => onSelect(homeId),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _WinnerChip(
            label: awayLabel,
            team: awayTeam,
            isSelected: effectiveWinner == awayId,
            canSelect: canSelect,
            onTap: () => onSelect(awayId),
          ),
        ),
      ],
    );
  }
}

class _WinnerChip extends StatelessWidget {
  final String label;
  final Team? team;
  final bool isSelected;
  final bool canSelect;
  final VoidCallback onTap;

  const _WinnerChip({
    required this.label,
    this.team,
    required this.isSelected,
    required this.canSelect,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF1A6B3C);
    final hasFlag = team?.flagAsset.isNotEmpty ?? false;

    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? green.withValues(alpha: 0.10)
              : Colors.grey.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? green : Colors.grey.withValues(alpha: 0.25),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (hasFlag) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Image.asset(
                  team!.flagAsset,
                  width: 22,
                  height: 14,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(width: 5),
            ] else if (isSelected) ...[
              const Icon(Icons.emoji_events_outlined, size: 12, color: green),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? green : Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
