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
        if (!_localCache.containsKey(projectId) || _localCache[projectId]!.isEmpty) {
          _localCache[projectId] = _buildSampleSprints(projectId);
        }
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[projectId]!));
        }
      },
    );

    return controller.stream;
  }

  Future<void> seedMockSprints(String projectId) async {
    final sampleSprints = _buildSampleSprints(projectId);

    _localCache[projectId] = sampleSprints;
    final controller = _getController(projectId);
    if (!controller.isClosed) {
      controller.add(List.from(sampleSprints));
    }

    try {
      final batch = _firestore.batch();
      for (final sprint in sampleSprints) {
        final docRef = _sprintsCollection(projectId).doc(sprint.id);
        batch.set(docRef, sprint.toMap());
      }
      await batch.commit();
    } catch (_) {
      // Ignore cloud errors
    }
  }

  List<SprintModel> _buildSampleSprints(String projectId) {
    final now = DateTime.now();
    return [
      SprintModel(
        id: 'mock_sprint_1',
        projectId: projectId,
        name: 'Sprint 1',
        goal: 'Hoàn thiện chức năng đăng nhập và khởi tạo dự án',
        startDate: now.subtract(const Duration(days: 7)),
        endDate: now.add(const Duration(days: 7)),
        status: 'Active',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
      SprintModel(
        id: 'mock_sprint_2',
        projectId: projectId,
        name: 'Sprint 2',
        goal: 'Quản lý User Story và Backlog',
        startDate: now.add(const Duration(days: 8)),
        endDate: now.add(const Duration(days: 22)),
        status: 'Planned',
        createdAt: now.subtract(const Duration(days: 8)),
        updatedAt: now.subtract(const Duration(days: 8)),
      ),
    ];
  }
}
