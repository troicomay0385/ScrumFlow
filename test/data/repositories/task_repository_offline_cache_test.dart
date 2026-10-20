import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/datasources/local_cache_datasource.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class MockDocumentReference extends Mock
    implements DocumentReference<Map<String, dynamic>> {}

class MockDocumentSnapshot extends Mock
    implements DocumentSnapshot<Map<String, dynamic>> {}

class MockQuery extends Mock implements Query<Map<String, dynamic>> {}

class MockQuerySnapshot extends Mock
    implements QuerySnapshot<Map<String, dynamic>> {}

class MockLocalCacheDataSource extends Mock implements LocalCacheDataSource {}

void main() {
  late MockFirebaseFirestore firestore;
  late MockCollectionReference collectionRef;
  late MockDocumentReference docRef;
  late MockDocumentSnapshot docSnapshot;
  late MockLocalCacheDataSource localCache;
  late TaskRepository repository;

  final sampleTask = TaskModel(
    id: 'task-1',
    storyId: 'story-1',
    projectId: 'project-1',
    title: 'Thực hiện chức năng US-062',
    description: 'Cache SQLite offline',
    status: 'To Do',
    assigneeId: 'user-1',
    assigneeName: 'Hieu',
    createdAt: DateTime(2026, 10, 1),
    updatedAt: DateTime(2026, 10, 1),
  );

  setUp(() {
    firestore = MockFirebaseFirestore();
    collectionRef = MockCollectionReference();
    docRef = MockDocumentReference();
    docSnapshot = MockDocumentSnapshot();
    localCache = MockLocalCacheDataSource();

    when(() => firestore.collection('tasks')).thenReturn(collectionRef);
    when(() => collectionRef.doc(any())).thenReturn(docRef);

    repository = TaskRepository(
      firestore: firestore,
      localCache: localCache,
    );
  });

  group('US-062: TaskRepository Offline Cache & Fallback', () {
    test('streamTask phát ngay lập tức task từ SQLite cache khi mở màn hình',
        () async {
      when(() => localCache.getCachedTask('task-1'))
          .thenAnswer((_) async => sampleTask);

      final firestoreController =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
      when(() => docRef.snapshots())
          .thenAnswer((_) => firestoreController.stream);

      final firstEvent = await repository.streamTask('task-1').first;

      expect(firstEvent?.id, 'task-1');
      expect(firstEvent?.title, 'Thực hiện chức năng US-062');

      await firestoreController.close();
    });

    test(
        'streamTask không phát null khi Firestore báo !exists lúc mất mạng nếu SQLite đã có cache',
        () async {
      when(() => localCache.getCachedTask('task-1'))
          .thenAnswer((_) async => sampleTask);

      final firestoreController =
          StreamController<DocumentSnapshot<Map<String, dynamic>>>.broadcast();
      when(() => docRef.snapshots())
          .thenAnswer((_) => firestoreController.stream);

      final events = <TaskModel?>[];
      final sub = repository.streamTask('task-1').listen(events.add);

      await pumpEventQueue();

      when(() => docSnapshot.exists).thenReturn(false);
      when(() => docSnapshot.data()).thenReturn(null);
      firestoreController.add(docSnapshot);

      await pumpEventQueue();

      expect(events.any((e) => e == null), isFalse);
      expect(events.last?.id, 'task-1');

      await sub.cancel();
      await firestoreController.close();
    });

    test('getTask trả về SQLite cache khi Firestore bị ngắt kết nối', () async {
      when(() => docRef.get()).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'));
      when(() => localCache.getCachedTask('task-1'))
          .thenAnswer((_) async => sampleTask);

      final result = await repository.getTask('task-1');

      expect(result, isNotNull);
      expect(result?.id, 'task-1');
      expect(result?.title, sampleTask.title);
    });

    test('streamTasksByStory phát ngay danh sách task từ SQLite cache khi mở',
        () async {
      final query = MockQuery();
      when(() => collectionRef.where('storyId', isEqualTo: 'story-1'))
          .thenReturn(query);

      final firestoreController =
          StreamController<QuerySnapshot<Map<String, dynamic>>>.broadcast();
      when(() => query.snapshots())
          .thenAnswer((_) => firestoreController.stream);

      when(() => localCache.getCachedTasks('story-1'))
          .thenAnswer((_) async => [sampleTask]);

      final firstList = await repository.streamTasksByStory('story-1').first;

      expect(firstList.length, 1);
      expect(firstList.first.id, 'task-1');

      await firestoreController.close();
    });
  });
}
