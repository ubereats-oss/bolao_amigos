import 'package:flutter/material.dart';
import '../../data/models/match.dart';
import '../../data/models/team.dart';
import '../../data/models/group_standing.dart';
import '../matches/bracket_engine.dart';

class GroupStandingsScreen extends StatelessWidget {
  final List<Match> groupMatches;
  // null = sem palpite salvo para aquele jogo
  final Map<String, List<int>?> palpites;
  final Map<String, Team> teams;

  const GroupStandingsScreen({
    super.key,
    required this.groupMatches,
    required this.palpites,
    required this.teams,
  });

  Map<String, GroupStanding> _computeStandings() {
    final engine = BracketEngine(
      groupMatches: groupMatches,
      groupPredictions: palpites,
      knockoutPredictions: {},
      groupTeams: {},
    );
    return engine.computeStandings();
  }

  @override
  Widget build(BuildContext context) {
    final standings = _computeStandings();
    final grupos = standings.keys.toList()..sort();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Classificação dos Grupos'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: grupos.length,
        itemBuilder: (context, i) {
          final groupId = grupos[i];
          final gs = standings[groupId]!;
          return _GroupCard(gs: gs, teams: teams);
        },
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  final GroupStanding gs;
  final Map<String, Team> teams;

  const _GroupCard({required this.gs, required this.teams});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A6B3C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Text(
              'Grupo ${gs.groupId}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                SizedBox(width: 28),
                Expanded(child: SizedBox()),
                SizedBox(
                  width: 32,
                  child: Text('Pts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 28,
                  child: Text('J',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 28,
                  child: Text('G',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  width: 28,
                  child: Text('S',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...gs.standings.asMap().entries.map((entry) {
            final pos = entry.key;
            final ts = entry.value;
            final team = teams[ts.teamId];
            final isClassified = pos < 2;
            final isThird = pos == 2;
            final jogos = _jogosJogados(ts);

            return Container(
              color: isClassified
                  ? const Color(0xFF1A6B3C).withValues(alpha: 0.06)
                  : isThird
                      ? Colors.orange.withValues(alpha: 0.06)
                      : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${pos + 1}º',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isClassified
                            ? const Color(0xFF1A6B3C)
                            : isThird
                                ? Colors.orange
                                : Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (team != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: Image.asset(
                        team.flagAsset,
                        width: 24,
                        height: 16,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.flag_outlined, size: 16),
                      ),
                    )
                  else
                    const SizedBox(width: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      team?.name ?? ts.teamId,
                      style: const TextStyle(fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    child: Text('${ts.points}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('$jogos',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text('${ts.goalsFor}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 13)),
                  ),
                  SizedBox(
                    width: 28,
                    child: Text(
                        '${ts.goalDiff > 0 ? '+' : ''}${ts.goalDiff}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: ts.goalDiff > 0
                              ? const Color(0xFF1A6B3C)
                              : ts.goalDiff < 0
                                  ? Colors.red
                                  : null,
                        )),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 10,
                    color: const Color(0xFF1A6B3C).withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                const Text('Classificado',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
                const SizedBox(width: 12),
                Container(
                    width: 10,
                    height: 10,
                    color: Colors.orange.withValues(alpha: 0.3)),
                const SizedBox(width: 4),
                const Text('Possível 3º classificado',
                    style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _jogosJogados(TeamStanding ts) => ts.gamesPlayed;
}
