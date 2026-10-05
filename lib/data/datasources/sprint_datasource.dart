import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sprint_model.dart';

class SprintDataSource {
  final FirebaseFirestore _firestore;

  static final Map<String, List<SprintModel>> _localCache = {};
  static final Map<String, StreamController<List<SprintModel>>> _controllers = {};

  SprintDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _sprintsCollection(String projectId) {
    return _firestore.collection('projects').doc(projectId).collection('sprints');
  }

  Future<SprintModel> createSprint(SprintModel sprint) async {
    final docRef = _sprintsCollection(sprint.projectId).doc();
    final created = sprint.copyWith(id: docRef.id);
    await docRef.set(created.toMap()).timeout(const Duration(seconds: 15));
    final sprints = List<SprintModel>.from(_localCache[sprint.projectId] ?? const []);
    sprints.add(created);
    _publish(sprint.projectId, sprints);
    return created;
  }

  Future<void> addStoryToSprint({
    required String projectId,
    required String sprintId,
    required String storyId,
  }) async {
    await addStoriesToSprint(
      projectId: projectId,
      sprintId: sprintId,
      storyIds: [storyId],
    );
  }

  Future<void> addStoriesToSprint({
    required String projectId,
    required String sprintId,
    required List<String> storyIds,
  }) async {
    if (storyIds.isEmpty) return;
    try {
      await _sprintsCollection(projectId).doc(sprintId).update({
        'storyIds': FieldValue.arrayUnion(storyIds),
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Offline fallback
    }

    final sprints = List<SprintModel>.from(_localCache[projectId] ?? const []);
    final index = sprints.indexWhere((sprint) => sprint.id == sprintId);
    if (index >= 0) {
      final updatedIds = {...sprints[index].storyIds, ...storyIds}.toList();
      sprints[index] = sprints[index].copyWith(
        storyIds: updatedIds,
        updatedAt: DateTime.now(),
      );
      _publish(projectId, sprints);
    }
  }

  Future<void> removeStoriesFromSprint({
    required String projectId,
    required String sprintId,
    required List<String> storyIds,
  }) async {
    if (storyIds.isEmpty) return;
    try {
      await _sprintsCollection(projectId).doc(sprintId).update({
        'storyIds': FieldValue.arrayRemove(storyIds),
        'updatedAt': DateTime.now().toIso8601String(),
      }).timeout(const Duration(seconds: 15));
    } catch (_) {
      // Offline fallback
    }

    final sprints = List<SprintModel>.from(_localCache[projectId] ?? const []);
    final index = sprints.indexWhere((sprint) => sprint.id == sprintId);
    if (index >= 0) {
      final updatedIds = sprints[index]
          .storyIds
          .where((id) => !storyIds.contains(id))
          .toList();
      sprints[index] = sprints[index].copyWith(
        storyIds: updatedIds,
        updatedAt: DateTime.now(),
      );
      _publish(projectId, sprints);
    }
  }

  void _publish(String projectId, List<SprintModel> sprints) {
    _localCache[projectId] = sprints;
    final controller = _getController(projectId);
    if (!controller.isClosed) controller.add(List.from(sprints));
  }

  StreamController<List<SprintModel>> _getController(String projectId) {
    if (!_controllers.containsKey(projectId) || _controllers[projectId]!.isClosed) {
      _controllers[projectId] = StreamController<List<SprintModel>>.broadcast();
    }
    return _controllers[projectId]!;
  }

  Stream<List<SprintModel>> streamSprints(String projectId) {
    final controller = _getController(projectId);

    if (_localCache.containsKey(projectId) && _localCache[projectId]!.isNotEmpty) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[projectId]!));
        }
      });
    }

    _sprintsCollection(projectId)
        .orderBy('startDate', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final sprints = snapshot.docs
            .map((doc) => SprintModel.fromMap(doc.data(), doc.id))
            .toList();
        _localCache[projectId] = sprints;
        if (!controller.isClosed) {
          controller.add(sprints);
        }
      },
      onError: (error) {
        if (!_localCache.containsKey(projectId)) {
          _localCache[projectId] = [];
        }
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[projectId]!));
        }
      },
    );

    return controller.stream;
  }

  Future<void> seedMockSprints(String projectId) async {
    // Chức năng tự sinh mẫu đã bị loại bỏ theo yêu cầu người dùng
  }
}
