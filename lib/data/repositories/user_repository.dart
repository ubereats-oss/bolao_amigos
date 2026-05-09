import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_user.dart';
class UserRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Future<List<AppUser>> fetchAllUsers() async {
    final snapshot = await _db.collection('users').orderBy('name').get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      // Email não é exposto no ranking
      return AppUser(
        id: doc.id,
        name: data['name'] ?? '',
        email: '',
        isAdmin: data['is_admin'] ?? false,
        totalPoints: data['total_points'] ?? 0,
      );
    }).toList();
  }
}
