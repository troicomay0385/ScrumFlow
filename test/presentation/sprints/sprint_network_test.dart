// US-063 — Danh sách Sprint: lỗi tải lần đầu có trạng thái riêng kèm "Thử
// lại"; lỗi thao tác KHÔNG làm mất danh sách đang hiển thị.
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/repositories/sprint_repository.dart';
import 'package:scrumflow/presentation/sprints/bloc/sprint_bloc.dart';
import 'package:scrumflow/presentation/sprints/bloc/sprint_event.dart';
import 'package:scrumflow/presentation/sprints/bloc/sprint_state.dart';

class _MockSprintRepository extends Mock implements SprintRepository {}

class _MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  const projectId = 'p1';
  late _MockSprintRepository repository;
  late _MockConnectivityService connectivity;

  final now = DateTime(2026, 10, 14);
  final sprint = SprintModel(
    id: 'sp1',
    projectId: projectId,
    name: 'Sprint 1',
    goal: '',
    startDate: now,
    endDate: now.add(const Duration(days: 14)),
    createdAt: now,
    updatedAt: now,
  );

  setUpAll(() => registerFallbackValue(DateTime(2026)));

  setUp(() {
    repository = _MockSprintRepository();
    connectivity = _MockConnectivityService();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  });

  blocTest<SprintBloc, SprintState>(
    'không có mạng → SprintLoadFailure(noConnection)',
    setUp: () =>
        when(() => connectivity.isOnline()).thenAnswer((_) async => false),
    build: () =>
        SprintBloc(repository: repository, connectivityService: connectivity),
    act: (bloc) => bloc.add(const SprintSubscriptionRequested(projectId)),
    expect: () => [
      isA<SprintLoading>(),
      isA<SprintLoadFailure>().having(
        (s) => s.failure.type,
        'type',
        AppFailureType.noConnection,
      ),
    ],
  );

  blocTest<SprintBloc, SprintState>(
    'không nhận được dữ liệu trong thời hạn → SprintLoadFailure(timeout)',
    setUp: () => when(
      () => repository.streamSprints(projectId),
    ).thenAnswer((_) => StreamController<List<SprintModel>>().stream),
    build: () => SprintBloc(
      repository: repository,
      connectivityService: connectivity,
      firstLoadTimeout: const Duration(milliseconds: 30),
    ),
    act: (bloc) => bloc.add(const SprintSubscriptionRequested(projectId)),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      isA<SprintLoading>(),
      isA<SprintLoadFailure>().having(
        (s) => s.failure.type,
        'type',
        AppFailureType.timeout,
      ),
    ],
  );

  test(
    'tạo Sprint thất bại → SprintError vẫn giữ danh sách hiện tại',
    () async {
      when(
        () => repository.streamSprints(projectId),
      ).thenAnswer((_) => Stream.value([sprint]));
      when(
        () => repository.createSprint(
          projectId: any(named: 'projectId'),
          name: any(named: 'name'),
          goal: any(named: 'goal'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenThrow(Exception('Bạn không có quyền tạo Sprint.'));
      final bloc = SprintBloc(
        repository: repository,
        connectivityService: connectivity,
      );

      bloc.add(const SprintSubscriptionRequested(projectId));
      await expectLater(bloc.stream, emitsThrough(isA<SprintLoaded>()));

      bloc.add(
        SprintCreateRequested(
          projectId: projectId,
          name: 'Sprint 2',
          goal: '',
          startDate: now,
          endDate: now.add(const Duration(days: 7)),
        ),
      );
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<SprintError>()
              .having(
                (s) => s.message,
                'message',
                'Bạn không có quyền tạo Sprint.',
              )
              .having((s) => s.sprints, 'sprints', [sprint]),
        ),
      );
      await bloc.close();
    },
  );
}
