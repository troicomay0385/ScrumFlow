// US-063 — Product Backlog: mất mạng, timeout lần tải đầu, lỗi stream và
// thử lại không tạo subscription trùng lặp.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_bloc.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_event.dart';
import 'package:scrumflow/presentation/backlog/bloc/backlog_state.dart';

class _MockBacklogRepository extends Mock implements BacklogRepository {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

UserStoryModel _story(String key) => UserStoryModel(
  id: key,
  projectId: 'p1',
  storyKey: key,
  title: key,
  description: '',
  createdAt: DateTime(2026, 10, 1),
  updatedAt: DateTime(2026, 10, 1),
);

void main() {
  const projectId = 'p1';
  late _MockBacklogRepository repository;
  late _MockConnectivityService connectivity;

  setUp(() {
    repository = _MockBacklogRepository();
    connectivity = _MockConnectivityService();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  });

  blocTest<BacklogBloc, BacklogState>(
    'không có mạng → BacklogError(noConnection), không mở stream Firestore',
    setUp: () =>
        when(() => connectivity.isOnline()).thenAnswer((_) async => false),
    build: () =>
        BacklogBloc(repository: repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(const BacklogSubscriptionRequested(projectId)),
    expect: () => [
      isA<BacklogLoading>(),
      isA<BacklogError>().having(
        (s) => s.failureType,
        'type',
        AppFailureType.noConnection,
      ),
    ],
    verify: (_) => verifyNever(() => repository.streamUserStories(any())),
  );

  blocTest<BacklogBloc, BacklogState>(
    'stream im lặng quá thời hạn → lỗi timeout (không loading vô tận)',
    // Stream không bao giờ phát gì — đúng hành vi Firestore khi không với
    // tới được máy chủ.
    setUp: () => when(
      () => repository.streamUserStories(projectId),
    ).thenAnswer((_) => StreamController<List<UserStoryModel>>().stream),
    build: () => BacklogBloc(
      repository: repository,
      connectivityService: connectivity,
      firstLoadTimeout: const Duration(milliseconds: 30),
    ),
    act: (bloc) => bloc.add(const BacklogSubscriptionRequested(projectId)),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<BacklogLoading>(),
      isA<BacklogError>().having(
        (s) => s.failureType,
        'type',
        AppFailureType.timeout,
      ),
    ],
  );

  test('dữ liệu tới muộn sau timeout → tự chuyển sang Loaded', () async {
    final controller = StreamController<List<UserStoryModel>>.broadcast();
    when(
      () => repository.streamUserStories(projectId),
    ).thenAnswer((_) => controller.stream);
    final bloc = BacklogBloc(
      repository: repository,
      connectivityService: connectivity,
      firstLoadTimeout: const Duration(milliseconds: 30),
    );

    bloc.add(const BacklogSubscriptionRequested(projectId));
    await expectLater(bloc.stream, emitsThrough(isA<BacklogError>()));
    controller.add([_story('US-001')]);
    await expectLater(bloc.stream, emitsThrough(isA<BacklogLoaded>()));

    await bloc.close();
    await controller.close();
  });

  blocTest<BacklogBloc, BacklogState>(
    'lỗi Firestore khi chưa có dữ liệu → thông báo thân thiện',
    setUp: () => when(() => repository.streamUserStories(projectId)).thenAnswer(
      (_) => Stream.error(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      ),
    ),
    build: () =>
        BacklogBloc(repository: repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(const BacklogSubscriptionRequested(projectId)),
    expect: () => [
      isA<BacklogLoading>(),
      isA<BacklogError>()
          .having((s) => s.failureType, 'type', AppFailureType.server)
          .having(
            (s) => s.message,
            'message',
            isNot(contains('cloud_firestore')),
          ),
    ],
  );

  test(
    'lỗi tạm thời khi đang hiển thị dữ liệu → giữ nguyên danh sách',
    () async {
      final controller = StreamController<List<UserStoryModel>>.broadcast();
      when(
        () => repository.streamUserStories(projectId),
      ).thenAnswer((_) => controller.stream);
      final bloc = BacklogBloc(
        repository: repository,
        connectivityService: connectivity,
      );

      bloc.add(const BacklogSubscriptionRequested(projectId));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.add([_story('US-001')]);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      controller.addError(
        FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(bloc.state, isA<BacklogLoaded>());
      expect((bloc.state as BacklogLoaded).stories, hasLength(1));
      await bloc.close();
      await controller.close();
    },
  );

  blocTest<BacklogBloc, BacklogState>(
    'stream kết thúc mà chưa có dữ liệu → báo lỗi, không kẹt loading',
    setUp: () => when(
      () => repository.streamUserStories(projectId),
    ).thenAnswer((_) => const Stream<List<UserStoryModel>>.empty()),
    build: () =>
        BacklogBloc(repository: repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(const BacklogSubscriptionRequested(projectId)),
    expect: () => [
      isA<BacklogLoading>(),
      isA<BacklogError>().having(
        (s) => s.failureType,
        'type',
        AppFailureType.unknown,
      ),
    ],
  );

  test('bấm "Thử lại" nhiều lần → chỉ còn 1 subscription đang mở', () async {
    var activeListeners = 0;
    when(() => repository.streamUserStories(projectId)).thenAnswer((_) {
      late StreamController<List<UserStoryModel>> c;
      c = StreamController<List<UserStoryModel>>(
        onListen: () => activeListeners++,
        onCancel: () => activeListeners--,
      );
      return c.stream;
    });
    final bloc = BacklogBloc(
      repository: repository,
      connectivityService: connectivity,
    );

    for (var i = 0; i < 3; i++) {
      bloc.add(const BacklogSubscriptionRequested(projectId));
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }

    expect(activeListeners, 1);
    await bloc.close();
    expect(activeListeners, 0);
  });
}
