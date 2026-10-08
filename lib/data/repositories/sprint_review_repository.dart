import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sprint_review_model.dart';

/// Repository quản lý kết quả Sprint Review (US-023).
class SprintReviewRepository {
  final FirebaseFirestore _firestore;
  static final Map<String, SprintReviewModel> _localCache = {};
  static final Map<String, StreamController<SprintReviewModel?>> _controllers = {};

  SprintReviewRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _reviewDoc(
      String projectId, String sprintId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('sprints')
        .doc(sprintId)
        .collection('review')
        .doc('summary');
  }

  String _cacheKey(String projectId, String sprintId) => '$projectId:$sprintId';

  Stream<SprintReviewModel?> streamSprintReview(
      String projectId, String sprintId) {
    final key = _cacheKey(projectId, sprintId);
    if (!_controllers.containsKey(key) || _controllers[key]!.isClosed) {
      _controllers[key] = StreamController<SprintReviewModel?>.broadcast();
    }
    final controller = _controllers[key]!;

    if (_localCache.containsKey(key)) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(_localCache[key]);
        }
      });
    }

    _reviewDoc(projectId, sprintId).snapshots().listen(
      (doc) {
        if (!doc.exists || doc.data() == null) {
          _localCache.remove(key);
          if (!controller.isClosed) controller.add(null);
        } else {
          final review = SprintReviewModel.fromMap(doc.data()!, doc.id);
          _localCache[key] = review;
          if (!controller.isClosed) controller.add(review);
        }
      },
      onError: (_) {
        if (!controller.isClosed) controller.add(_localCache[key]);
      },
    );

    return controller.stream;
  }

  Future<void> saveSprintReview(SprintReviewModel review) async {
    final key = _cacheKey(review.projectId, review.sprintId);
    _localCache[key] = review;

    if (_controllers.containsKey(key) && !_controllers[key]!.isClosed) {
      _controllers[key]!.add(review);
    }

    try {
      await _reviewDoc(review.projectId, review.sprintId)
          .set(review.toMap(), SetOptions(merge: true))
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      // Local fallback
    }
  }
}
