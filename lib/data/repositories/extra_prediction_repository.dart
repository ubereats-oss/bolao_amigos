import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/extra_question.dart';
import '../models/extra_prediction.dart';
import '../models/team.dart';
import '../models/player.dart';
class ExtraPredictionRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Busca todas as perguntas extras de uma copa, ordenadas
  Future<List<ExtraQuestion>> fetchQuestions(String cupId) async {
    final snapshot = await _db
        .collection('cups')
        .doc(cupId)
        .collection('extra_questions')
        .orderBy('order')
        .get();
    return snapshot.docs
        .map((doc) => ExtraQuestion.fromFirestore(doc.id, doc.data()))
        .toList();
  }
  // Busca todos os palpites extras de um usuário
  Future<Map<String, ExtraPrediction>> fetchUserPredictions(
      String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('extra_predictions')
        .get();
    return {
      for (final doc in snapshot.docs)
        doc.id: ExtraPrediction.fromFirestore(doc.id, doc.data())
    };
  }
  // Salva ou atualiza um palpite extra
  Future<void> savePrediction(ExtraPrediction prediction) async {
    await _db
        .collection('users')
        .doc(prediction.userId)
        .collection('extra_predictions')
        .doc(prediction.questionId)
        .set({
      ...prediction.toFirestore(),
      'saved_at': FieldValue.serverTimestamp(),
    });
  }
  // Busca todos os times de uma copa
  Future<List<Team>> fetchTeams(String cupId) async {
    final snapshot = await _db
        .collection('cups')
        .doc(cupId)
        .collection('teams')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => Team.fromFirestore(doc.id, doc.data()))
        .toList();
  }
  // Busca todos os jogadores de uma copa
  Future<List<Player>> fetchPlayers(String cupId) async {
    final snapshot = await _db
        .collection('cups')
        .doc(cupId)
        .collection('players')
        .orderBy('name')
        .get();
    return snapshot.docs
        .map((doc) => Player.fromFirestore(doc.id, doc.data()))
        .toList();
  }
}
