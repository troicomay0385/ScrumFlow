import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/repositories/work_log_repository.dart';
import 'package:scrumflow/presentation/tasks/bloc/log_work_cubit.dart';
import 'package:scrumflow/presentation/tasks/bloc/log_work_state.dart';

class MockWorkLogRepository extends Mock implements WorkLogRepository {}

class FakeTaskModel extends Fake implements TaskModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTaskModel());
  });

  const projectId = 'proj-1';
  const taskId = 'task-1';
  final now = DateTime(2026, 10, 17);

  final testTask = TaskModel(
    id: taskId,
    storyId: 'story-1',
    projectId: projectId,
    title: 'Viết unit test',
    description: 'Chi tiết task',
    status: 'To Do',
    loggedHours: 0.0,
    createdAt: now,
    updatedAt: now,
  );

  late MockWorkLogRepository repository;

  setUp(() {
    repository = MockWorkLogRepository();
  });

  blocTest<LogWorkCubit, LogWorkState>(
    'submit thành công → Submitting → Success, gọi repository đúng tham số',
    build: () {
      when(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: any(named: 'hours'),
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).thenAnswer((_) async {});
      return LogWorkCubit(
        repository: repository,
        task: testTask,
        projectId: projectId,
      );
    },
    act: (cubit) => cubit.submit(
      hours: 2.5,
      note: 'Viết test cho LogWorkCubit',
      workDate: now,
    ),
    expect: () => [
      const LogWorkSubmitting(),
      const LogWorkSuccess(),
    ],
    verify: (_) {
      verify(() => repository.logWork(
            task: testTask,
            projectId: projectId,
            hours: 2.5,
            note: 'Viết test cho LogWorkCubit',
            workDate: now,
          )).called(1);
    },
  );

  blocTest<LogWorkCubit, LogWorkState>(
    'giờ không hợp lệ (null, <= 0, > 24, không là bội số 0.25) → Failure, KHÔNG gọi repository',
    build: () => LogWorkCubit(
      repository: repository,
      task: testTask,
      projectId: projectId,
    ),
    act: (cubit) async {
      await cubit.submit(hours: null, note: '', workDate: now);
      await cubit.submit(hours: 0, note: '', workDate: now);
      await cubit.submit(hours: 25, note: '', workDate: now);
      await cubit.submit(hours: 1.1, note: '', workDate: now);
    },
    expect: () => [
      const LogWorkFailure('Vui lòng nhập số giờ làm việc'),
      const LogWorkFailure('Số giờ làm việc phải lớn hơn 0'),
      const LogWorkFailure('Số giờ làm việc không được vượt quá 24 giờ'),
      const LogWorkFailure('Số giờ phải là bội số của 0.25 (ví dụ: 0.25, 0.5, 0.75, 1)'),
    ],
    verify: (_) {
      verifyNoMoreInteractions(repository);
    },
  );

  blocTest<LogWorkCubit, LogWorkState>(
    'ghi chú quá 500 ký tự → Failure, KHÔNG gọi repository',
    build: () => LogWorkCubit(
      repository: repository,
      task: testTask,
      projectId: projectId,
    ),
    act: (cubit) => cubit.submit(
      hours: 1.0,
      note: 'x' * 501,
      workDate: now,
    ),
    expect: () => [
      const LogWorkFailure('Ghi chú không được vượt quá 500 ký tự'),
    ],
    verify: (_) {
      verifyNoMoreInteractions(repository);
    },
  );

  blocTest<LogWorkCubit, LogWorkState>(
    'ngày làm việc ở tương lai → Failure, KHÔNG gọi repository',
    build: () => LogWorkCubit(
      repository: repository,
      task: testTask,
      projectId: projectId,
    ),
    act: (cubit) => cubit.submit(
      hours: 1.0,
      note: 'Note',
      workDate: DateTime.now().add(const Duration(days: 3)),
    ),
    expect: () => [
      const LogWorkFailure('Ngày làm việc không được ở tương lai'),
    ],
    verify: (_) {
      verifyNoMoreInteractions(repository);
    },
  );

  blocTest<LogWorkCubit, LogWorkState>(
    'lỗi từ repository → Failure với thông báo tiếng Việt',
    build: () {
      when(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: any(named: 'hours'),
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).thenThrow(
              Exception('Chỉ thành viên của dự án mới được ghi giờ làm việc.'));
      return LogWorkCubit(
        repository: repository,
        task: testTask,
        projectId: projectId,
      );
    },
    act: (cubit) => cubit.submit(
      hours: 2.0,
      note: '',
      workDate: now,
    ),
    expect: () => [
      const LogWorkSubmitting(),
      const LogWorkFailure('Chỉ thành viên của dự án mới được ghi giờ làm việc.'),
    ],
  );

  blocTest<LogWorkCubit, LogWorkState>(
    'bấm submit nhiều lần liên tiếp / đã thành công → repository chỉ được gọi 1 lần',
    build: () {
      final completer = Completer<void>();
      when(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: any(named: 'hours'),
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).thenAnswer((_) => completer.future);

      Future<void>.delayed(
        const Duration(milliseconds: 20),
        () => completer.complete(),
      );

      return LogWorkCubit(
        repository: repository,
        task: testTask,
        projectId: projectId,
      );
    },
    act: (cubit) async {
      final first = cubit.submit(hours: 1.0, note: 'Tác vụ 1', workDate: now);
      // Gọi liên tiếp khi đang submitting
      unawaited(cubit.submit(hours: 1.0, note: 'Tác vụ 1', workDate: now));
      unawaited(cubit.submit(hours: 1.0, note: 'Tác vụ 1', workDate: now));
      await first;
      // Gọi khi đã success
      await cubit.submit(hours: 1.0, note: 'Tác vụ 1', workDate: now);
    },
    expect: () => [
      const LogWorkSubmitting(),
      const LogWorkSuccess(),
    ],
    verify: (_) {
      verify(() => repository.logWork(
            task: any(named: 'task'),
            projectId: any(named: 'projectId'),
            hours: any(named: 'hours'),
            note: any(named: 'note'),
            workDate: any(named: 'workDate'),
          )).called(1);
    },
  );
}
