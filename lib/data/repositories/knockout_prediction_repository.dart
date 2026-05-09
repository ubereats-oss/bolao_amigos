import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/knockout_prediction.dart';

class KnockoutPredictionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference _predictions(String groupId, String userId) => _db
      .collection('bolao_groups')
      .doc(groupId)
      .collection('members')
      .doc(userId)
      .collection('knockout_predictions');

  Future<Map<String, KnockoutPrediction>> fetchAll(
      String groupId, String userId) async {
    final snap = await _predictions(groupId, userId).get();
    return {
      for (final doc in snap.docs)
        doc.id: KnockoutPrediction.fromFirestore(
            doc.id, doc.data() as Map<String, dynamic>)
    };
  }

  Future<void> save(String groupId, KnockoutPrediction p) async {
    await _predictions(groupId, p.userId).doc(p.slotId).set({
      ...p.toFirestore(),
      'saved_at': FieldValue.serverTimestamp(),
    });
  }
}
