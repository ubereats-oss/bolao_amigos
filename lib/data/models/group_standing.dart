class TeamStanding {
  final String teamId;
  int points;
  int goalsFor;
  int goalsAgainst;
  int gamesPlayed;

  TeamStanding({
    required this.teamId,
    this.points = 0,
    this.goalsFor = 0,
    this.goalsAgainst = 0,
    this.gamesPlayed = 0,
  });

  int get goalDiff => goalsFor - goalsAgainst;
}

class GroupStanding {
  final String groupId; // 'A' .. 'L'
  final List<TeamStanding> standings;

  const GroupStanding({required this.groupId, required this.standings});

  /// 1º colocado
  String get first => standings[0].teamId;

  /// 2º colocado
  String get second => standings[1].teamId;

  /// 3º colocado
  String get third => standings[2].teamId;
}
