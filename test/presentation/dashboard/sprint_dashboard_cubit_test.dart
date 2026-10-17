import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/errors/app_failure.dart';
import 'package:scrumflow/app/services/connectivity_service.dart';
import 'package:scrumflow/data/models/sprint_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/repositories/sprint_repository.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/presentation/dashboard/bloc/sprint_dashboard_cubit.dart';
import 'package:scrumflow/presentation/dashboard/bloc/sprint_dashboard_state.dart';

class MockSprintRepository extends Mock implements SprintRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockConnectivityService extends Mock implements ConnectivityService {}

void main() {
  late MockSprintRepository sprintRepository;
  late MockTaskRepository taskRepository;
  late MockConnectivityService connectivityService;

  late StreamController<List<SprintModel>> sprintController;
  late StreamController<List<TaskModel>> taskController;

  SprintModel createSprint({
    String id = 'sprint-1',
    String projectId = 'p1',
    String name = 'Sprint 1',
    String status = 'Active',
    List<String> storyIds = const ['s1'],
  }) {
    final now = DateTime(2026, 10, 1);
    return SprintModel(
      id: id,
      projectId: projectId,
      name: name,
      goal: 'Mục tiêu sprint',
      status: status,
      storyIds: storyIds,
      startDate: now,
      endDate: now.add(const Duration(days: 14)),
      createdAt: now,
      updatedAt: now,
    );
  }

  TaskModel createTask({
    required String id,
    required String storyId,
    required String status,
  }) {
    final now = DateTime(2026, 10, 1);
    return TaskModel(
      id: id,
      storyId: storyId,
      title: 'Task $id',
      description: '',
      status: status,
      createdAt: now,
      updatedAt: now,
    );
  }

  setUp(() {
    sprintRepository = MockSprintRepository();
    taskRepository = MockTaskRepository();
    connectivityService = MockConnectivityService();

    sprintController = StreamController<List<SprintModel>>.broadcast();
    taskController = StreamController<List<TaskModel>>.broadcast();

    when(() => connectivityService.isOnline()).thenAnswer((_) async => true);
    when(() => sprintRepository.streamSprints(any()))
        .thenAnswer((_) => sprintController.stream);
    when(() => taskRepository.streamTasksByStories(any()))
        .thenAnswer((_) => taskController.stream);
  });

  tearDown(() {
    sprintController.close();
    taskController.close();
  });

  group('SprintDashboardCubit', () {
    test('loading -> noSprint khi dự án không có Sprint Active', () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      expect(cubit.state.status, SprintDashboardStatus.loading);

      unawaited(cubit.load('p1'));
      await pumpEventQueue();
      expect(cubit.state.status, SprintDashboardStatus.loading);

      // Phát danh sách sprint chỉ có Planned, không có Active
      sprintController.add([createSprint(status: 'Planned')]);
      await pumpEventQueue();

      expect(cubit.state.status, SprintDashboardStatus.noSprint);
      expect(cubit.state.sprint, isNull);
      expect(cubit.state.progress, isNull);

      await cubit.close();
    });

    test('loading -> loaded với đúng số To Do / In Progress / Done', () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      unawaited(cubit.load('p1'));
      await pumpEventQueue();

      // Phát Sprint Active với storyId 's1'
      final sprint = createSprint(status: 'Active', storyIds: ['s1']);
      sprintController.add([sprint]);
      await pumpEventQueue();

      // Phát tasks thuộc sprint
      final tasks = [
        createTask(id: 't1', storyId: 's1', status: 'To Do'),
        createTask(id: 't2', storyId: 's1', status: 'In Progress'),
        createTask(id: 't3', storyId: 's1', status: 'Done'),
      ];
      taskController.add(tasks);
      await pumpEventQueue();

      expect(cubit.state.status, SprintDashboardStatus.loaded);
      expect(cubit.state.sprint, sprint);
      expect(cubit.state.progress!.todo, 1);
      expect(cubit.state.progress!.inProgress, 1);
      expect(cubit.state.progress!.done, 1);
      expect(cubit.state.progress!.total, 3);
      expect(cubit.state.progress!.donePercent, 33);

      await cubit.close();
    });

    test('Sprint đổi storyIds thì huỷ subscription cũ và subscribe lại task',
        () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      unawaited(cubit.load('p1'));
      await pumpEventQueue();

      // Lần 1: sprint có storyIds ['s1']
      sprintController.add([createSprint(storyIds: ['s1'])]);
      await pumpEventQueue();
      verify(() => taskRepository.streamTasksByStories(['s1'])).called(1);

      // Lần 2: sprint đổi sang storyIds ['s1', 's2']
      sprintController.add([createSprint(storyIds: ['s1', 's2'])]);
      await pumpEventQueue();
      verify(() => taskRepository.streamTasksByStories(['s1', 's2'])).called(1);

      await cubit.close();
    });

    test('Sprint đổi tên (không đổi storyIds) thì không subscribe lại task',
        () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      unawaited(cubit.load('p1'));
      await pumpEventQueue();

      // Lần 1: tên 'Sprint 1', storyIds ['s1']
      sprintController.add([createSprint(name: 'Sprint 1', storyIds: ['s1'])]);
      await pumpEventQueue();
      verify(() => taskRepository.streamTasksByStories(['s1'])).called(1);

      // Lần 2: tên đổi thành 'Sprint 1 Mới', storyIds vẫn là ['s1']
      sprintController
          .add([createSprint(name: 'Sprint 1 Mới', storyIds: ['s1'])]);
      await pumpEventQueue();

      // Không subscribe lại task
      verifyNever(() => taskRepository.streamTasksByStories(['s1']));
      expect(cubit.state.sprint!.name, 'Sprint 1 Mới');

      await cubit.close();
    });

    test('stream lỗi -> emit error với failure phân loại từ AppErrorHandler',
        () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      unawaited(cubit.load('p1'));
      await pumpEventQueue();

      sprintController.addError(TimeoutException('Quá thời gian'));
      await pumpEventQueue();

      expect(cubit.state.status, SprintDashboardStatus.error);
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.failure!.type, AppFailureType.timeout);

      await cubit.close();
    });

    test('đổi projectId giữa chừng thì dữ liệu project cũ bị bỏ qua', () async {
      final sprintControllerP1 =
          StreamController<List<SprintModel>>.broadcast();
      final sprintControllerP2 =
          StreamController<List<SprintModel>>.broadcast();

      when(() => sprintRepository.streamSprints('p1'))
          .thenAnswer((_) => sprintControllerP1.stream);
      when(() => sprintRepository.streamSprints('p2'))
          .thenAnswer((_) => sprintControllerP2.stream);

      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      // Bắt đầu load p1 rồi ngay sau đó load p2
      unawaited(cubit.load('p1'));
      unawaited(cubit.load('p2'));
      await pumpEventQueue();

      // Stream của p1 emit trễ -> phải bị bỏ qua
      sprintControllerP1.add([createSprint(projectId: 'p1', name: 'Sprint P1')]);
      await pumpEventQueue();
      expect(cubit.state.projectId, 'p2');
      expect(cubit.state.sprint, isNull);

      // Stream của p2 emit -> được chấp nhận
      final sprintP2 = createSprint(projectId: 'p2', name: 'Sprint P2');
      sprintControllerP2.add([sprintP2]);
      await pumpEventQueue();
      expect(cubit.state.projectId, 'p2');
      expect(cubit.state.sprint, sprintP2);

      await sprintControllerP1.close();
      await sprintControllerP2.close();
      await cubit.close();
    });

    test('retry không chạy lại khi đang ở trạng thái loading', () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      unawaited(cubit.load('p1'));
      await pumpEventQueue();
      expect(cubit.state.status, SprintDashboardStatus.loading);

      // Gọi retry khi đang loading -> không làm gì cả
      cubit.retry();
      await pumpEventQueue();

      verify(() => sprintRepository.streamSprints('p1')).called(1);

      await cubit.close();
    });

    test('close huỷ toàn bộ subscription của sprint và task', () async {
      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      unawaited(cubit.load('p1'));
      await pumpEventQueue();

      expect(sprintController.hasListener, isTrue);

      sprintController.add([createSprint(status: 'Active', storyIds: ['s1'])]);
      await pumpEventQueue();
      expect(taskController.hasListener, isTrue);

      await cubit.close();
      await pumpEventQueue();

      expect(sprintController.hasListener, isFalse);
      expect(taskController.hasListener, isFalse);
    });

    test('khi mất mạng ban đầu: emit error với AppFailure.noConnection', () async {
      when(() => connectivityService.isOnline()).thenAnswer((_) async => false);

      final cubit = SprintDashboardCubit(
        sprintRepository,
        taskRepository,
        connectivity: connectivityService,
      );

      await cubit.load('p1');

      expect(cubit.state.status, SprintDashboardStatus.error);
      expect(cubit.state.failure!.type, AppFailureType.noConnection);

      await cubit.close();
    });
  });
}
