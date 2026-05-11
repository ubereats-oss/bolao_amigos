import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bolao_group.dart';
import '../models/prediction.dart';
import '../models/extra_prediction.dart';

class GroupRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _groups => _db.collection('bolao_groups');

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  Future<String> _generateUniqueCode() async {
    for (var i = 0; i < 20; i++) {
      final code = _generateCode();
      final doc = await _db.collection('invite_codes').doc(code).get();
      if (!doc.exists) return code;
    }
    throw Exception('Não foi possível gerar um código de convite único.');
  }

  // ── Criar grupo ──────────────────────────────────────────────────────────
  Future<BolaoGroup> createGroup({
    required String name,
    required String cupId,
    required String adminUid,
  }) async {
    final inviteCode = await _generateUniqueCode();
    final now = FieldValue.serverTimestamp();

    final ref = await _groups.add({
      'name': name.trim(),
      'admin_uid': adminUid,
      'invite_code': inviteCode,
      'cup_id': cupId,
      'created_at': now,
    });

    await ref.collection('members').doc(adminUid).set({
      'role': 'admin',
      'points': 0,
      'joined_at': now,
    });

    await _db.collection('invite_codes').doc(inviteCode).set({
      'group_id': ref.id,
      'created_by': adminUid,
      'created_at': now,
    });

    await _db.collection('users').doc(adminUid).set({
      'group_ids': FieldValue.arrayUnion([ref.id]),
    }, SetOptions(merge: true));

    final doc = await ref.get();
    return BolaoGroup.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── Entrar por código de convite ─────────────────────────────────────────
  Future<BolaoGroup?> joinByCode(String code, String userId) async {
    final normalized = code.trim().toUpperCase();
    final inviteDoc = await _db.collection('invite_codes').doc(normalized).get();
    if (!inviteDoc.exists) return null;

    final inviteData = inviteDoc.data() ?? {};
    final groupId = inviteData['group_id'] as String?;
    if (groupId == null || groupId.isEmpty) return null;
    final groupRef = _groups.doc(groupId);

    final memberDoc = await groupRef.collection('members').doc(userId).get();
    if (memberDoc.exists) {
      final doc = await groupRef.get();
      if (!doc.exists) return null;
      return BolaoGroup.fromFirestore(
          doc.id, doc.data() as Map<String, dynamic>);
    }

    await groupRef.collection('members').doc(userId).set({
      'role': 'member',
      'points': 0,
      'invite_code': normalized,
      'joined_at': FieldValue.serverTimestamp(),
    });

    await _db.collection('users').doc(userId).set({
      'group_ids': FieldValue.arrayUnion([groupId]),
    }, SetOptions(merge: true));

    final doc = await groupRef.get();
    if (!doc.exists) return null;
    return BolaoGroup.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
  }

  // ── Buscar grupos do usuário ─────────────────────────────────────────────
  Future<List<BolaoGroup>> fetchUserGroups(String userId) async {
    final userDoc = await _db.collection('users').doc(userId).get();
    final data = userDoc.data() ?? {};
    final ids = List<String>.from(data['group_ids'] ?? []);
    if (ids.isEmpty) return [];

    final docs = await Future.wait(ids.map((id) => _groups.doc(id).get()));
    return docs
        .where((d) => d.exists)
        .map((d) =>
            BolaoGroup.fromFirestore(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  // ── Buscar membros de um grupo ───────────────────────────────────────────
  Future<List<BolaoMember>> fetchMembers(String groupId) async {
    final snap = await _groups.doc(groupId).collection('members').get();
    return snap.docs
        .map((d) => BolaoMember.fromFirestore(d.id, d.data()))
        .toList();
  }

  // ── Palpite de jogo por grupo ────────────────────────────────────────────
  CollectionReference _predictions(String groupId, String userId) => _groups
      .doc(groupId)
      .collection('members')
      .doc(userId)
      .collection('predictions');

  Future<Prediction?> fetchPrediction(
      String groupId, String userId, String matchId) async {
    final doc = await _predictions(groupId, userId).doc(matchId).get();
    if (!doc.exists) return null;
    return Prediction.fromFirestore(matchId, doc.data() as Map<String, dynamic>);
  }

  Future<Map<String, Prediction>> fetchAllPredictions(
      String groupId, String userId) async {
    final snap = await _predictions(groupId, userId).get();
    return {
      for (final d in snap.docs)
        d.id: Prediction.fromFirestore(d.id, d.data() as Map<String, dynamic>)
    };
  }

  Future<void> savePrediction(String groupId, Prediction p) async {
    await _predictions(groupId, p.userId).doc(p.matchId).set({
      ...p.toFirestore(),
      'saved_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteAllPredictions(String groupId, String userId) async {
    final snap = await _predictions(groupId, userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  // ── Palpite extra por grupo ──────────────────────────────────────────────
  CollectionReference _extraPredictions(String groupId, String userId) =>
      _groups
          .doc(groupId)
          .collection('members')
          .doc(userId)
          .collection('extra_predictions');

  Future<Map<String, ExtraPrediction>> fetchAllExtraPredictions(
      String groupId, String userId) async {
    final snap = await _extraPredictions(groupId, userId).get();
    return {
      for (final d in snap.docs)
        d.id: ExtraPrediction.fromFirestore(
            d.id, d.data() as Map<String, dynamic>)
    };
  }

  Future<void> saveExtraPrediction(
      String groupId, ExtraPrediction p) async {
    await _extraPredictions(groupId, p.userId)
        .doc(p.questionId)
        .set({
      ...p.toFirestore(),
      'saved_at': FieldValue.serverTimestamp(),
    });
  }

  // ── Verificar se usuário é membro ────────────────────────────────────────
  Future<BolaoMember?> fetchMember(String groupId, String userId) async {
    final doc =
        await _groups.doc(groupId).collection('members').doc(userId).get();
    if (!doc.exists) return null;
    return BolaoMember.fromFirestore(doc.id, doc.data()!);
  }

  // ── Sair do grupo ────────────────────────────────────────────────────────
  Future<void> leaveGroup(String groupId, String userId) async {
    await _groups.doc(groupId).collection('members').doc(userId).delete();
    await _db.collection('users').doc(userId).update({
      'group_ids': FieldValue.arrayRemove([groupId]),
    });
  }

  // ── Deletar grupo (apenas admin) ─────────────────────────────────────────
  Future<void> deleteGroup(String groupId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await _groups.doc(groupId).delete();
    await _db.collection('users').doc(uid).update({
      'group_ids': FieldValue.arrayRemove([groupId]),
    });
  }
}
