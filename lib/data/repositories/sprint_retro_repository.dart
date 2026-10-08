import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sprint_retro_item_model.dart';

/// Repository quản lý Sprint Retrospective (US-024).
class SprintRetroRepository {
  final FirebaseFirestore _firestore;

  static final Map<String, List<SprintRetroItemModel>> _localCache = {};
  static final Map<String, StreamController<List<SprintRetroItemModel>>> _controllers = {};

  SprintRetroRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _retroCollection(
      String projectId, String sprintId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('sprints')
        .doc(sprintId)
        .collection('retro_items');
  }

  String _cacheKey(String projectId, String sprintId) => '$projectId:$sprintId';

  Stream<List<SprintRetroItemModel>> streamRetroItems(
      String projectId, String sprintId) {
    final key = _cacheKey(projectId, sprintId);
    if (!_controllers.containsKey(key) || _controllers[key]!.isClosed) {
      _controllers[key] = StreamController<List<SprintRetroItemModel>>.broadcast();
    }
    final controller = _controllers[key]!;

    if (_localCache.containsKey(key)) {
      Future.microtask(() {
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[key]!));
        }
      });
    }

    _retroCollection(projectId, sprintId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .listen(
      (snapshot) {
        final items = snapshot.docs
            .map((doc) => SprintRetroItemModel.fromMap(doc.data(), doc.id))
            .toList();
        _localCache[key] = items;
        if (!controller.isClosed) controller.add(items);
      },
      onError: (_) {
        if (!controller.isClosed) {
          controller.add(List.from(_localCache[key] ?? []));
        }
      },
    );

    return controller.stream;
  }

  Future<SprintRetroItemModel> addRetroItem({
    required String projectId,
    required String sprintId,
    required RetroColumnType column,
    required String content,
    required String authorId,
    required String authorName,
  }) async {
    final key = _cacheKey(projectId, sprintId);
    final docRef = _retroCollection(projectId, sprintId).doc();
    final now = DateTime.now();

    final item = SprintRetroItemModel(
      id: docRef.id,
      sprintId: sprintId,
      projectId: projectId,
      column: column,
      content: content.trim(),
      authorId: authorId,
      authorName: authorName,
      createdAt: now,
    );

    final current = List<SprintRetroItemModel>.from(_localCache[key] ?? []);
    current.add(item);
    _localCache[key] = current;
    if (_controllers.containsKey(key) && !_controllers[key]!.isClosed) {
      _controllers[key]!.add(List.from(current));
    }

    try {
      await docRef.set(item.toMap()).timeout(const Duration(seconds: 15));
    } catch (_) {}

    return item;
  }

  Future<void> toggleVote({
    required String projectId,
    required String sprintId,
    required String itemId,
    required String userId,
  }) async {
    final key = _cacheKey(projectId, sprintId);
    final current = List<SprintRetroItemModel>.from(_localCache[key] ?? []);
    final idx = current.indexWhere((it) => it.id == itemId);

    if (idx >= 0) {
      final item = current[idx];
      final voters = List<String>.from(item.voterIds);
      if (voters.contains(userId)) {
        voters.remove(userId);
      } else {
        voters.add(userId);
      }
      current[idx] = item.copyWith(voterIds: voters);
      _localCache[key] = current;
      if (_controllers.containsKey(key) && !_controllers[key]!.isClosed) {
        _controllers[key]!.add(List.from(current));
      }

      try {
        final docRef = _retroCollection(projectId, sprintId).doc(itemId);
        if (voters.contains(userId)) {
          await docRef.update({
            'voterIds': FieldValue.arrayUnion([userId])
          });
        } else {
          await docRef.update({
            'voterIds': FieldValue.arrayRemove([userId])
          });
        }
      } catch (_) {}
    }
  }

  Future<void> deleteRetroItem({
    required String projectId,
    required String sprintId,
    required String itemId,
  }) async {
    final key = _cacheKey(projectId, sprintId);
    final current = List<SprintRetroItemModel>.from(_localCache[key] ?? []);
    current.removeWhere((it) => it.id == itemId);
    _localCache[key] = current;
    if (_controllers.containsKey(key) && !_controllers[key]!.isClosed) {
      _controllers[key]!.add(List.from(current));
    }

    try {
      await _retroCollection(projectId, sprintId).doc(itemId).delete();
    } catch (_) {}
  }
}
