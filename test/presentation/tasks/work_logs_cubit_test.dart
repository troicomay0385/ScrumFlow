import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';
import 'package:scrumflow/data/models/work_log_model.dart';
import 'package:scrumflow/data/repositories/work_log_repository.dart';
import 'package:scrumflow/presentation/tasks/bloc/work_logs_cubit.dart';
import 'package:scrumflow/presentation/tasks/bloc/work_logs_state.dart';

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  const taskId = 'task-100';
  final now = DateTime(2026, 10, 17);

  final testLogs = [
    WorkLogModel(
      id: 'log-1',
      taskId: taskId,
      projectId: 'proj-1',
      userId: 'user-1',
      userName: 'Nguyễn Hiếu',
      hours: 2.0,
      note: 'Phát triển Cubit',
      workDate: now,
      createdAt: now,
    ),
  ];

  late MockWorkLogRepository repository;
  late MockConnectivityService connectivity;

  setUp(() {
    repository = MockWorkLogRepository();
    connectivity = MockConnectivityService();
    when(() => connectivity.isOnline()).thenAnswer((_) async => true);
  });

  group('WorkLogsCubit', () {
    test('initial state hợp lệ', () {
      final cubit = WorkLogsCubit(repository, connectivity: connectivity);
      expect(cubit.state.status, equals(WorkLogsStatus.loading));
      expect(cubit.state.workLogs, isEmpty);
      expect(cubit.state.failure, isNull);
      cubit.close();
    });

    blocTest<WorkLogsCubit, WorkLogsState>(
      'tự động load khi taskId được truyền vào constructor và emit loaded khi có dữ liệu',
      build: () {
        when(() => repository.streamWorkLogs(taskId))
            .thenAnswer((_) => Stream.value(testLogs));
        return WorkLogsCubit(
          repository,
          taskId: taskId,
          connectivity: connectivity,
        );
      },
      expect: () => [
        const WorkLogsState(
          status: WorkLogsStatus.loading,
          taskId: taskId,
        ),
        WorkLogsState(
          status: WorkLogsStatus.loaded,
          taskId: taskId,
          workLogs: testLogs,
        ),
      ],
    );

    blocTest<WorkLogsCubit, WorkLogsState>(
      'emit empty khi stream trả về danh sách rỗng',
      build: () {
        when(() => repository.streamWorkLogs(taskId))
            .thenAnswer((_) => Stream.value([]));
        return WorkLogsCubit(
          repository,
          connectivity: connectivity,
        );
      },
      act: (cubit) => cubit.load(taskId),
      expect: () => [
        const WorkLogsState(
          status: WorkLogsStatus.loading,
          taskId: taskId,
        ),
        const WorkLogsState(
          status: WorkLogsStatus.empty,
          taskId: taskId,
          workLogs: [],
        ),
      ],
    );

    blocTest<WorkLogsCubit, WorkLogsState>(
      'emit error khi kiểm tra mất kết nối mạng',
      build: () {
        when(() => connectivity.isOnline()).thenAnswer((_) async => false);
        return WorkLogsCubit(
          repository,
          connectivity: connectivity,
        );
      },
      act: (cubit) => cubit.load(taskId),
      expect: () => [
        const WorkLogsState(
          status: WorkLogsStatus.loading,
          taskId: taskId,
        ),
        const WorkLogsState(
          status: WorkLogsStatus.error,
          taskId: taskId,
          failure: AppFailure.noConnection(),
        ),
      ],
      verify: (_) {
        verifyZeroInteractions(repository);
      },
    );

    blocTest<WorkLogsCubit, WorkLogsState>(
      'emit error khi stream phát lỗi',
      build: () {
        when(() => repository.streamWorkLogs(taskId))
            .thenAnswer((_) => Stream.error(Exception('Lỗi Firestore')));
        return WorkLogsCubit(
          repository,
          connectivity: connectivity,
        );
      },
      act: (cubit) => cubit.load(taskId),
      expect: () => [
        const WorkLogsState(
          status: WorkLogsStatus.loading,
          taskId: taskId,
        ),
        predicate<WorkLogsState>((state) =>
            state.status == WorkLogsStatus.error &&
            state.taskId == taskId &&
            state.failure != null),
      ],
    );

    test('retry gọi lại repository.streamWorkLogs', () async {
      when(() => repository.streamWorkLogs(taskId))
          .thenAnswer((_) => Stream.value(testLogs));

      final cubit = WorkLogsCubit(
        repository,
        connectivity: connectivity,
      );

      await cubit.load(taskId);
      verify(() => repository.streamWorkLogs(taskId)).called(1);

      await cubit.retry();
      verify(() => repository.streamWorkLogs(taskId)).called(1);

      await cubit.close();
    });
  });
}
