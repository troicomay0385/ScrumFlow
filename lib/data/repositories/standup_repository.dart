import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/standup_model.dart';

class StandupRepository {
  final FirebaseFirestore _firestore;

  StandupRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> addStandup(StandupModel standup) async {
    final docRef = _firestore.collection('standups').doc();
    final newStandup = standup.copyWith(id: docRef.id);
    await docRef.set(newStandup.toMap());
  }

  Future<List<StandupModel>> getStandupsBySprintId(String sprintId) async {
    final querySnapshot = await _firestore
        .collection('standups')
        .where('sprintId', isEqualTo: sprintId)
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => StandupModel.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<StandupModel>> getStandupsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final querySnapshot = await _firestore
        .collection('standups')
        // createdAt in StandupModel is saved as ISO8601 string, which allows string comparison
        .where('createdAt', isGreaterThanOrEqualTo: startDate.toIso8601String())
        .where('createdAt', isLessThanOrEqualTo: endDate.toIso8601String())
        .orderBy('createdAt', descending: true)
        .get();

    return querySnapshot.docs.map((doc) => StandupModel.fromMap(doc.data(), doc.id)).toList();
  }
}
