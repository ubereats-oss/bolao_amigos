import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/bolao_group.dart';
import '../../data/models/app_user.dart';
import '../../services/auth_service.dart';

class _RankingEntry {
  final BolaoMember member;
  final AppUser? user;

  const _RankingEntry({required this.member, required this.user});

  String get name => user?.name ?? 'Participante';
}

class RankingScreen extends StatefulWidget {
  final String groupId;

  const RankingScreen({super.key, required this.groupId});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  final _authService = AuthService();
  final Map<String, AppUser?> _userCache = {};

  List<_RankingEntry> _entries = [];
  bool _loading = true;
  String? _currentUid;
  StreamSubscription<QuerySnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _currentUid = FirebaseAuth.instance.currentUser?.uid;
    _subscription = FirebaseFirestore.instance
        .collection('bolao_groups')
        .doc(widget.groupId)
        .collection('members')
        .orderBy('points', descending: true)
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
    super.dispose();
  }

  Future<void> _onSnapshot(QuerySnapshot snap) async {
    final members = snap.docs
        .map((d) =>
            BolaoMember.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();

    final entries = await Future.wait(
      members.map((m) async {
        _userCache[m.userId] ??= await _authService.fetchAppUser(m.userId);
        return _RankingEntry(member: m, user: _userCache[m.userId]);
      }),
    );

    if (mounted) {
      setState(() {
        _entries = entries;
        _loading = false;
      });
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
                    final posicao = index + 1;
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
                          '${entry.member.points} pts',
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
