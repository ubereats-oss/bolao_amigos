import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/bolao_group.dart';
import '../../data/models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/scoring_service.dart';

class _RankingEntry {
  final BolaoMember member;
  final AppUser? user;
  final int matchPoints;
  final int extraPoints;

  const _RankingEntry({
    required this.member,
    required this.user,
    required this.matchPoints,
    required this.extraPoints,
  });

  String get name => user?.name ?? 'Participante';
  int get totalPoints => matchPoints + extraPoints;
}

class RankingScreen extends StatefulWidget {
  final String groupId;

  const RankingScreen({super.key, required this.groupId});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _scoringService = ScoringService();
  final Map<String, AppUser?> _userCache = {};
  final List<BolaoMember> _members = [];

  List<_RankingEntry> _entries = [];
  bool _loading = true;
  String? _currentUid;
  StreamSubscription<QuerySnapshot>? _subscription;
  StreamSubscription<QuerySnapshot>? _matchesSubscription;
  StreamSubscription<QuerySnapshot>? _questionsSubscription;
  String? _watchedCupId;
  bool _refreshing = false;
  bool _refreshAgain = false;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _subscription = FirebaseFirestore.instance
        .collection('bolao_groups')
        .doc(widget.groupId)
        .collection('members')
        .snapshots()
        .listen(
          _onSnapshot,
          onError: (_) {
            if (mounted) setState(() => _loading = false);
          },
        );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _matchesSubscription?.cancel();
    _questionsSubscription?.cancel();
    super.dispose();
  }

  Future<void> _onSnapshot(QuerySnapshot snap) async {
    _members
      ..clear()
      ..addAll(snap.docs
        .map((d) =>
            BolaoMember.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList());
    await _recarregarPontuacao();
  }

  void _ativarEscutaDoCup(String cupId) {
    if (_watchedCupId == cupId) return;
    _watchedCupId = cupId;
    _matchesSubscription?.cancel();
    _questionsSubscription?.cancel();
    _matchesSubscription = FirebaseFirestore.instance
        .collectionGroup('matches')
        .snapshots()
        .listen((_) => _recarregarPontuacao());
    _questionsSubscription = FirebaseFirestore.instance
        .collection('cups')
        .doc(cupId)
        .collection('extra_questions')
        .snapshots()
        .listen((_) => _recarregarPontuacao());
  }

  Future<void> _recarregarPontuacao() async {
    if (_members.isEmpty) return;
    if (_refreshing) {
      _refreshAgain = true;
      return;
    }
    _refreshing = true;
    try {
      final cup = await _firestoreService.fetchActiveCup();
      if (cup != null) {
        _ativarEscutaDoCup(cup.id);
      }

      final entries = await Future.wait(
        _members.map((m) async {
          _userCache[m.userId] ??= await _authService.fetchAppUser(m.userId);
          final breakdown = cup == null
              ? const ScoringBreakdown(matchPoints: 0, extraPoints: 0)
              : await _scoringService.calcularDetalhado(
                  groupId: widget.groupId,
                  userId: m.userId,
                  cupId: cup.id,
                );
          return _RankingEntry(
            member: m,
            user: _userCache[m.userId],
            matchPoints: breakdown.matchPoints,
            extraPoints: breakdown.extraPoints,
          );
        }),
      );
      entries.sort((a, b) {
        final total = b.totalPoints.compareTo(a.totalPoints);
        if (total != 0) return total;
        final extras = b.extraPoints.compareTo(a.extraPoints);
        if (extras != 0) return extras;
        return a.name.compareTo(b.name);
      });

      if (mounted) {
        setState(() {
          _entries = entries;
          _loading = false;
        });
      }
    } finally {
      _refreshing = false;
      if (_refreshAgain) {
        _refreshAgain = false;
        await _recarregarPontuacao();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        backgroundColor: const Color(0xFF1A6B3C),
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _entries.isEmpty
              ? const Center(child: Text('Nenhum participante ainda.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _entries.length,
                  itemBuilder: (context, index) {
                    final entry = _entries[index];
                    final posicao = _rankingPosition(_entries, index);
                    final isMe = entry.member.userId == _currentUid;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0xFF1A6B3C).withValues(alpha: 0.08)
                            : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: _PosicaoWidget(posicao: posicao),
                        title: Text(
                          entry.name,
                          style: TextStyle(
                            fontWeight: isMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: isMe
                            ? const Text(
                                'Você',
                                style: TextStyle(
                                    color: Color(0xFF1A6B3C), fontSize: 12),
                              )
                            : null,
                        trailing: Text(
                          '${entry.totalPoints} pts',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

int _rankingPosition(List<_RankingEntry> entries, int index) {
  if (index == 0) return 1;
  final atual = entries[index];
  final anterior = entries[index - 1];
  if (atual.totalPoints == anterior.totalPoints &&
      atual.extraPoints == anterior.extraPoints) {
    return _rankingPosition(entries, index - 1);
  }
  return index + 1;
}

class _PosicaoWidget extends StatelessWidget {
  final int posicao;

  const _PosicaoWidget({required this.posicao});

  @override
  Widget build(BuildContext context) {
    if (posicao == 1) return const Text('🥇', style: TextStyle(fontSize: 28));
    if (posicao == 2) return const Text('🥈', style: TextStyle(fontSize: 28));
    if (posicao == 3) return const Text('🥉', style: TextStyle(fontSize: 28));
    return SizedBox(
      width: 36,
      child: Text(
        '$posicao°',
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }
}
