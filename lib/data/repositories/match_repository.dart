import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/match.dart';
import '../models/team.dart';

class MatchRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Cache em memória por copa
  static final Map<String, List<Match>> _groupMatchesCache = {};
  static final Map<String, List<Match>> _knockoutMatchesCache = {};
  static final Map<String, Map<String, Team>> _teamsCache = {};
  static void clearCache() {
    _groupMatchesCache.clear();
    _knockoutMatchesCache.clear();
    _teamsCache.clear();
  }

  Future<List<Match>> fetchGroupMatches(String cupId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _groupMatchesCache.containsKey(cupId)) {
      return _groupMatchesCache[cupId]!;
    }
    final groupsSnapshot =
        await _db.collection('cups').doc(cupId).collection('groups').get();
    final List<Match> matches = [];
    for (final groupDoc in groupsSnapshot.docs) {
      final matchesSnapshot = await _db
          .collection('cups')
          .doc(cupId)
          .collection('groups')
          .doc(groupDoc.id)
          .collection('matches')
          .get();
      for (final doc in matchesSnapshot.docs) {
        final data = doc.data()
          ..['group_id'] = groupDoc.id.toLowerCase()
          ..['home_team_id'] = (doc.data()['home_team_id'] ?? '').toString().toLowerCase()
          ..['away_team_id'] = (doc.data()['away_team_id'] ?? '').toString().toLowerCase();
        matches.add(Match.fromFirestore(doc.id, data));
      }
    }
    matches.sort((a, b) => a.matchTime.compareTo(b.matchTime));
    _groupMatchesCache[cupId] = matches;
    return matches;
  }

  Future<List<Match>> fetchKnockoutMatches(String cupId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _knockoutMatchesCache.containsKey(cupId)) {
      return _knockoutMatchesCache[cupId]!;
    }
    final snapshot = await _db
        .collection('cups')
        .doc(cupId)
        .collection('knockout_matches')
        .get();
    final matches = snapshot.docs
        .map((doc) => Match.fromFirestore(doc.id, doc.data()))
        .toList();
    matches.sort((a, b) => a.matchTime.compareTo(b.matchTime));
    _knockoutMatchesCache[cupId] = matches;
    return matches;
  }

  Future<Match?> fetchMatch(
      String cupId, String matchId, String? groupId) async {
    DocumentSnapshot doc;
    if (groupId != null) {
      doc = await _db
          .collection('cups')
          .doc(cupId)
          .collection('groups')
          .doc(groupId)
          .collection('matches')
          .doc(matchId)
          .get();
    } else {
      doc = await _db
          .collection('cups')
          .doc(cupId)
          .collection('knockout_matches')
          .doc(matchId)
          .get();
    }
    if (!doc.exists) return null;
    return Match.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  Future<Map<String, Team>> fetchTeams(String cupId,
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _teamsCache.containsKey(cupId)) {
      return _teamsCache[cupId]!;
    }
    final snapshot =
        await _db.collection('cups').doc(cupId).collection('teams').get();
    final teams = {
      for (final doc in snapshot.docs)
        doc.id: Team.fromFirestore(doc.id, doc.data())
    };
    _teamsCache[cupId] = teams;
    return teams;
  }
}
