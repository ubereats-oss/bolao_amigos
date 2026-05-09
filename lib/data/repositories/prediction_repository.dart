import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/prediction.dart';
class PredictionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Busca palpite de um usuário para um jogo
  Future<Prediction?> fetchPrediction(String userId, String matchId) async {
    final doc = await _db
        .collection('users')
        .doc(userId)
        .collection('predictions')
        .doc(matchId)
        .get();
    if (!doc.exists) return null;
    return Prediction.fromFirestore(matchId, doc.data()!);
  }
  // Busca todos os palpites de um usuário
  Future<List<Prediction>> fetchAllPredictions(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('predictions')
        .get();
    return snapshot.docs
        .map((doc) => Prediction.fromFirestore(doc.id, doc.data()))
        .toList();
  }
  // Salva ou atualiza palpite
  Future<void> savePrediction(Prediction prediction) async {
    await _db
        .collection('users')
        .doc(prediction.userId)
        .collection('predictions')
        .doc(prediction.matchId)
        .set({
      ...prediction.toFirestore(),
      'saved_at': FieldValue.serverTimestamp(),
    });
  }
}
