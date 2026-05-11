import '../../core/constants/bracket_data.dart';
import '../../data/models/group_standing.dart';
import '../../data/models/match.dart';
import '../../data/models/knockout_prediction.dart';

/// Resultado resolvido de um confronto do mata-mata
class ResolvedMatch {
  final BracketMatchDef def;
  final String? homeTeamId;
  final String? awayTeamId;
  final bool canPredict;
  // Labels legíveis do slot, ex: '1º A', '2º B', 'Melhor 3º (A/B/C/D/F)'
  final String homeSlotLabel;
  final String awaySlotLabel;

  const ResolvedMatch({
    required this.def,
    this.homeTeamId,
    this.awayTeamId,
    required this.canPredict,
    required this.homeSlotLabel,
    required this.awaySlotLabel,
  });
}

class BracketEngine {
  final List<Match> groupMatches;
  // null = sem palpite (jogo ignorado no cálculo de classificação)
  final Map<String, List<int>?> groupPredictions;
  final Map<String, KnockoutPrediction> knockoutPredictions;
  final Map<String, List<String>> groupTeams;

  BracketEngine({
    required this.groupMatches,
    required this.groupPredictions,
    required this.knockoutPredictions,
    required this.groupTeams,
  });

  // ─── Monta groupTeams de forma robusta ────────────────────────────────────
  Map<String, List<String>> _effectiveGroupTeams() {
    if (groupTeams.isNotEmpty) {
      return groupTeams;
    }
    final Map<String, List<String>> result = {};
    for (final m in groupMatches) {
      final gid = m.groupId;
      if (gid == null || gid.isEmpty) continue;
      result.putIfAbsent(gid, () => []);
      if (!result[gid]!.contains(m.homeTeamId)) result[gid]!.add(m.homeTeamId);
      if (!result[gid]!.contains(m.awayTeamId)) result[gid]!.add(m.awayTeamId);
    }
    return result;
  }

  // ─── Cálculo das tabelas de grupo ─────────────────────────────────────────

  Map<String, GroupStanding> computeStandings() {
    final effective = _effectiveGroupTeams();
    final Map<String, Map<String, TeamStanding>> raw = {};
    for (final entry in effective.entries) {
      raw[entry.key] = {
        for (final t in entry.value) t: TeamStanding(teamId: t)
      };
    }

    for (final match in groupMatches) {
      final gid = match.groupId;
      if (gid == null || gid.isEmpty) continue;

      final palpite = groupPredictions[match.id];
      if (palpite == null) continue; // sem palpite: ignora no cálculo

      final hGoals = palpite[0];
      final aGoals = palpite[1];

      final home = raw[gid]?[match.homeTeamId];
      final away = raw[gid]?[match.awayTeamId];
      if (home == null || away == null) continue;

      home.goalsFor += hGoals;
      home.goalsAgainst += aGoals;
      home.gamesPlayed += 1;
      away.goalsFor += aGoals;
      away.goalsAgainst += hGoals;
      away.gamesPlayed += 1;

      if (hGoals > aGoals) {
        home.points += 3;
      } else if (hGoals == aGoals) {
        home.points += 1;
        away.points += 1;
      } else {
        away.points += 3;
      }
    }

    final result = <String, GroupStanding>{};
    for (final entry in raw.entries) {
      final sorted = entry.value.values.toList()
        ..sort((a, b) {
          final pts = b.points.compareTo(a.points);
          if (pts != 0) return pts;
          final diff = b.goalDiff.compareTo(a.goalDiff);
          if (diff != 0) return diff;
          final gf = b.goalsFor.compareTo(a.goalsFor);
          if (gf != 0) return gf;
          return a.teamId.compareTo(b.teamId);
        });
      result[entry.key] = GroupStanding(groupId: entry.key, standings: sorted);
    }
    return result;
  }

  // ─── Melhores 3ºs colocados ────────────────────────────────────────────────

  List<MapEntry<String, TeamStanding>> computeBestThirds(
      Map<String, GroupStanding> standings) {
    final thirds = <MapEntry<String, TeamStanding>>[];
    for (final gs in standings.values) {
      if (gs.standings.length >= 3 &&
          gs.standings.every((ts) => ts.gamesPlayed > 0)) {
        thirds.add(MapEntry(gs.groupId, gs.standings[2]));
      }
    }
    thirds.sort((a, b) {
      final pts = b.value.points.compareTo(a.value.points);
      if (pts != 0) return pts;
      final diff = b.value.goalDiff.compareTo(a.value.goalDiff);
      if (diff != 0) return diff;
      final gf = b.value.goalsFor.compareTo(a.value.goalsFor);
      if (gf != 0) return gf;
      return a.key.compareTo(b.key);
    });
    return thirds.take(8).toList();
  }

  // ─── Atribuição dos melhores 3ºs via backtracking ─────────────────────────
  //
  // O algoritmo greedy sequencial falha quando os candidatos se sobrepõem
  // (ex: grupo I aparece em 6 dos 8 slots). O backtracking garante encontrar
  // a atribuição válida para qualquer combinação de 8 grupos qualificados.
  //
  // Retorna mapa de "${def.id}_h" ou "${def.id}_a" → teamId.

  Map<String, String?> _assignBestThirds(
      List<MapEntry<String, TeamStanding>> bestThirds) {
    final defIds = <String>[];
    final isHomeSlot = <bool>[];
    final groupCandidates = <List<String>>[];

    for (final def in BracketData.r32) {
      if (def.home.isThird) {
        defIds.add(def.id);
        isHomeSlot.add(true);
        groupCandidates.add(def.home.thirdGroups);
      }
      if (def.away.isThird) {
        defIds.add(def.id);
        isHomeSlot.add(false);
        groupCandidates.add(def.away.thirdGroups);
      }
    }

    final assignment = <int, int>{}; // slotIndex -> bestThirds index
    final usedIdx = <int>{};

    bool backtrack(int si) {
      if (si >= defIds.length) return true;
      final groups = groupCandidates[si];

      for (int ti = 0; ti < bestThirds.length; ti++) {
        if (usedIdx.contains(ti)) continue;
        if (!groups.contains(bestThirds[ti].key)) continue;

        assignment[si] = ti;
        usedIdx.add(ti);
        if (backtrack(si + 1)) return true;
        assignment.remove(si);
        usedIdx.remove(ti);
      }
      return false;
    }

    backtrack(0);

    final result = <String, String?>{};
    for (int si = 0; si < defIds.length; si++) {
      final key = '${defIds[si]}_${isHomeSlot[si] ? 'h' : 'a'}';
      final ti = assignment[si];
      result[key] = ti != null ? bestThirds[ti].value.teamId : null;
    }
    return result;
  }

  // ─── Resolução de slots (exceto Melhor 3º, tratado por _assignBestThirds) ──

  String? resolveSlot(
    String code,
    Map<String, GroupStanding> standings,
    Map<String, String> winners,
  ) {
    if (code.startsWith('W') || code.startsWith('L')) {
      final isWinner = code.startsWith('W');
      final matchId = code.substring(1);
      return isWinner ? winners['W$matchId'] : winners['L$matchId'];
    }
    if (code.startsWith('1') || code.startsWith('2')) {
      final pos = int.parse(code[0]) - 1;
      final groupId = code.substring(1).toLowerCase();
      final gs = standings[groupId];
      if (gs == null || gs.standings.length <= pos) return null;
      // Só mostra o time se todos os times do grupo tiverem pelo menos 1 jogo previsto
      if (gs.standings.any((ts) => ts.gamesPlayed == 0)) return null;
      return gs.standings[pos].teamId;
    }
    return null;
  }

  // ─── Label legível do slot ─────────────────────────────────────────────────

  String _slotLabel(String code) {
    if (code.startsWith('W')) return 'Vencedor ${code.substring(1)}';
    if (code.startsWith('L')) return 'Perdedor ${code.substring(1)}';
    if (code.startsWith('1')) return '1º ${code.substring(1)}';
    if (code.startsWith('2')) return '2º ${code.substring(1)}';
    if (code.startsWith('3')) {
      final grupos = code.substring(1).split('').join('/');
      return 'Melhor 3º ($grupos)';
    }
    return code;
  }

  // ─── Resolução completa do chaveamento ─────────────────────────────────────

  List<ResolvedMatch> resolveAll() {
    final standings = computeStandings();
    final bestThirds = computeBestThirds(standings);
    final thirdsAssignment = _assignBestThirds(bestThirds);

    final Map<String, String> resolved = {};
    final phaseOrder = ['r32', 'r16', 'qf', 'sf', 'final', '3rd'];
    final result = <ResolvedMatch>[];
    final phasePredicted = <String, bool>{};
    phasePredicted['group'] = true;

    for (final phase in phaseOrder) {
      final matches = BracketData.matchesForPhase(phase);
      final prevPhase = _previousPhase(phase);
      final prevDone = phasePredicted[prevPhase] ?? false;
      bool allThisPhasePredicted = true;

      for (final def in matches) {
        final homeId = def.home.isThird
            ? thirdsAssignment['${def.id}_h']
            : resolveSlot(def.home.code, standings, resolved);

        final awayId = def.away.isThird
            ? thirdsAssignment['${def.id}_a']
            : resolveSlot(def.away.code, standings, resolved);

        final canPredict = prevDone && homeId != null && awayId != null;

        result.add(ResolvedMatch(
          def: def,
          homeTeamId: homeId,
          awayTeamId: awayId,
          canPredict: canPredict,
          homeSlotLabel: _slotLabel(def.home.code),
          awaySlotLabel: _slotLabel(def.away.code),
        ));

        final pred = knockoutPredictions[def.id];
        if (pred != null && homeId != null && awayId != null) {
          String winner;
          String loser;
          if (pred.winner != null) {
            // vencedor explícito tem prioridade sobre placar
            winner = pred.winner!;
            loser = winner == homeId ? awayId : homeId;
          } else if (pred.homeGoals != null && pred.awayGoals != null) {
            if (pred.homeGoals! > pred.awayGoals!) {
              winner = homeId;
              loser = awayId;
            } else if (pred.awayGoals! > pred.homeGoals!) {
              winner = awayId;
              loser = homeId;
            } else {
              winner = homeId; // empate: time da casa avança (padrão)
              loser = awayId;
            }
          } else {
            winner = homeId;
            loser = awayId;
          }
          resolved['W${def.id}'] = winner;
          resolved['L${def.id}'] = loser;
        } else {
          allThisPhasePredicted = false;
        }
      }

      phasePredicted[phase] = allThisPhasePredicted;
    }

    return result;
  }

  String _previousPhase(String phase) {
    switch (phase) {
      case 'r32':
        return 'group';
      case 'r16':
        return 'r32';
      case 'qf':
        return 'r16';
      case 'sf':
        return 'qf';
      case 'final':
        return 'sf';
      case '3rd':
        return 'sf';
      default:
        return 'group';
    }
  }
}
