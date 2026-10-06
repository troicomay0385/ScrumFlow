import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/models/project_member_display.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/presentation/tasks/bloc/task_detail_cubit.dart';
import 'package:scrumflow/presentation/tasks/bloc/task_detail_state.dart';

class MockTaskRepository extends Mock implements TaskRepository {}

class MockProjectMemberRepository extends Mock
    implements ProjectMemberRepository {}

ProjectMemberDisplay member(String uid, String name, ProjectRole role) {
  final at = DateTime(2026, 9, 1);
  return ProjectMemberDisplay(
    membership: ProjectMemberModel(
      id: 'p1_$uid',
      projectId: 'p1',
      userId: uid,
      role: role,
      createdBy: 'u-phuc',
      createdAt: at,
      updatedAt: at,
    ),
    user: UserModel(
      id: uid,
      fullName: name,
      email: '$uid@scrumflow.com',
      createdAt: at,
      loginProvider: 'email',
    ),
  );
}

void main() {
  const projectId = 'p1';
  final today = DateTime(2026, 10, 6, 15, 30);
  final members = [
    member('u-phuc', 'Phúc', ProjectRole.po),
    member('u-hieu', 'Hiếu', ProjectRole.sm),
    member('u-duy', 'Duy', ProjectRole.member),
  ];

  TaskModel buildTask({String? projectId = 'p1', DateTime? deadline}) =>
      TaskModel(
        id: 't1',
        storyId: 's1',
        projectId: projectId,
        title: 'Thiết kế màn hình Login',
        description: '',
        assigneeId: 'u-phuc',
        assigneeName: 'Phúc',
        deadline: deadline,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

  late MockTaskRepository taskRepository;
  late MockProjectMemberRepository memberRepository;
  late StreamController<TaskModel?> taskStream;

  /// Cubit đã `start()` và đã nhận xong members + role.
  Future<TaskDetailCubit> buildStarted({
    ProjectRole? role = ProjectRole.member,
    TaskModel? task,
  }) async {
    when(() => memberRepository.streamCurrentUserRole(projectId))
        .thenAnswer((_) => Stream.value(role));
    final cubit = TaskDetailCubit(
      taskRepository: taskRepository,
      memberRepository: memberRepository,
      projectId: projectId,
      task: task ?? buildTask(),
      now: () => today,
    )..start();
    await pumpEventQueue();
    return cubit;
  }

  void stubAssignee(Future<void> Function() answer) {
    when(() => taskRepository.updateTaskAssignee(
          taskId: any(named: 'taskId'),
          taskTitle: any(named: 'taskTitle'),
          assigneeId: any(named: 'assigneeId'),
          assigneeName: any(named: 'assigneeName'),
        )).thenAnswer((_) => answer());
  }

  void stubDeadline(Future<void> Function() answer) {
    when(() => taskRepository.updateTaskDeadline(
          taskId: any(named: 'taskId'),
          deadline: any(named: 'deadline'),
        )).thenAnswer((_) => answer());
  }

  setUp(() {
    taskRepository = MockTaskRepository();
    memberRepository = MockProjectMemberRepository();
    taskStream = StreamController<TaskModel?>.broadcast();
    when(() => taskRepository.streamTask('t1'))
        .thenAnswer((_) => taskStream.stream);
    when(() => memberRepository.streamMembers(projectId))
        .thenAnswer((_) => Stream.value(members));
    when(() => taskRepository.attachProject(
          taskId: any(named: 'taskId'),
          projectId: any(named: 'projectId'),
        )).thenAnswer((_) async {});
  });

  tearDown(() => taskStream.close());

  group('start', () {
    test('nạp thành viên thực tế của project và role hiện tại', () async {
      final cubit = await buildStarted(role: ProjectRole.sm);
      expect(cubit.state.members, members);
      expect(cubit.state.membersLoaded, isTrue);
      expect(cubit.state.role, ProjectRole.sm);
      expect(cubit.state.canAssign, isTrue);
      expect(cubit.state.canSetDeadline, isTrue);
      await cubit.close();
    });

    test('cập nhật real-time khi task đổi trên Firestore; task bị xoá → null',
        () async {
      final cubit = await buildStarted();
      taskStream.add(buildTask().copyWith(assigneeId: 'u-duy', assigneeName: 'Duy'));
      await pumpEventQueue();
      expect(cubit.state.task!.assigneeName, 'Duy');

      taskStream.add(null);
      await pumpEventQueue();
      expect(cubit.state.task, isNull);
      await cubit.close();
    });

    test('task đã có projectId → không ghi lại projectId', () async {
      final cubit = await buildStarted();
      expect(cubit.state.projectLinked, isTrue);
      verifyNever(() => taskRepository.attachProject(
            taskId: any(named: 'taskId'),
            projectId: any(named: 'projectId'),
          ));
      await cubit.close();
    });

    test('task cũ chưa có projectId → gắn vào project đang mở', () async {
      final cubit = await buildStarted(task: buildTask(projectId: null));
      verify(() => taskRepository.attachProject(taskId: 't1', projectId: 'p1'))
          .called(1);
      expect(cubit.state.projectLinked, isTrue);
      await cubit.close();
    });

    test('gắn project thất bại → không crash, bình luận chưa sẵn sàng',
        () async {
      when(() => taskRepository.attachProject(
            taskId: any(named: 'taskId'),
            projectId: any(named: 'projectId'),
          )).thenThrow(Exception('Không có quyền truy cập dữ liệu.'));
      final cubit = await buildStarted(task: buildTask(projectId: null));
      expect(cubit.state.projectLinked, isFalse);
      expect(cubit.state.task, isNotNull);
      await cubit.close();
    });
  });

  group('US-043 — changeAssignee', () {
    for (final role in ProjectRole.values) {
      test('${role.toFirestoreValue()} đổi assignee sang thành viên khác',
          () async {
        stubAssignee(() async {});
        final cubit = await buildStarted(role: role);

        await cubit.changeAssignee('u-hieu');

        verify(() => taskRepository.updateTaskAssignee(
              taskId: 't1',
              taskTitle: 'Thiết kế màn hình Login',
              assigneeId: 'u-hieu',
              assigneeName: 'Hiếu',
            )).called(1);
        expect(cubit.state.status, TaskDetailStatus.saved);
        expect(cubit.state.message, 'Đã giao task cho Hiếu');
        await cubit.close();
      });
    }

    test('không cho chọn user không thuộc project', () async {
      final cubit = await buildStarted();

      await cubit.changeAssignee('u-nguoi-ngoai');

      expect(cubit.state.status, TaskDetailStatus.failure);
      expect(cubit.state.message,
          'Người được chọn không phải thành viên của project.');
      verifyNever(() => taskRepository.updateTaskAssignee(
            taskId: any(named: 'taskId'),
            taskTitle: any(named: 'taskTitle'),
            assigneeId: any(named: 'assigneeId'),
            assigneeName: any(named: 'assigneeName'),
          ));
      await cubit.close();
    });

    test('user không phải thành viên project (role null) bị từ chối', () async {
      final cubit = await buildStarted(role: null);

      await cubit.changeAssignee('u-hieu');

      expect(cubit.state.status, TaskDetailStatus.failure);
      verifyNever(() => taskRepository.updateTaskAssignee(
            taskId: any(named: 'taskId'),
            taskTitle: any(named: 'taskTitle'),
            assigneeId: any(named: 'assigneeId'),
            assigneeName: any(named: 'assigneeName'),
          ));
      await cubit.close();
    });

    test('bỏ phân công (null) được phép', () async {
      stubAssignee(() async {});
      final cubit = await buildStarted();

      await cubit.changeAssignee(null);

      verify(() => taskRepository.updateTaskAssignee(
            taskId: 't1',
            taskTitle: any(named: 'taskTitle'),
            assigneeId: null,
            assigneeName: null,
          )).called(1);
      expect(cubit.state.message, 'Đã bỏ phân công task');
      await cubit.close();
    });

    test('chọn lại đúng assignee hiện tại → không ghi Firestore', () async {
      final cubit = await buildStarted();
      await cubit.changeAssignee('u-phuc');
      expect(cubit.state.status, TaskDetailStatus.idle);
      verifyNever(() => taskRepository.updateTaskAssignee(
            taskId: any(named: 'taskId'),
            taskTitle: any(named: 'taskTitle'),
            assigneeId: any(named: 'assigneeId'),
            assigneeName: any(named: 'assigneeName'),
          ));
      await cubit.close();
    });

    blocTest<TaskDetailCubit, TaskDetailState>(
      'Firestore lỗi → saving rồi failure kèm thông báo dễ hiểu',
      build: () {
        stubAssignee(() async => throw Exception('Không có quyền truy cập dữ liệu.'));
        when(() => memberRepository.streamCurrentUserRole(projectId))
            .thenAnswer((_) => Stream.value(ProjectRole.member));
        return TaskDetailCubit(
          taskRepository: taskRepository,
          memberRepository: memberRepository,
          projectId: projectId,
          task: buildTask(),
          now: () => today,
        )..start();
      },
      act: (cubit) async {
        await pumpEventQueue();
        await cubit.changeAssignee('u-duy');
      },
      skip: 2, // members + role
      expect: () => [
        isA<TaskDetailState>()
            .having((s) => s.status, 'status', TaskDetailStatus.saving),
        isA<TaskDetailState>()
            .having((s) => s.status, 'status', TaskDetailStatus.failure)
            .having((s) => s.message, 'message',
                'Không có quyền truy cập dữ liệu.')
            .having((s) => s.task!.assigneeId, 'assignee giữ nguyên', 'u-phuc'),
      ],
    );
  });

  group('US-044 — setDeadline', () {
    for (final role in ProjectRole.values) {
      test('${role.toFirestoreValue()} đặt deadline cho task chưa có deadline',
          () async {
        stubDeadline(() async {});
        final cubit = await buildStarted(role: role);
        expect(cubit.state.task!.deadline, isNull);

        await cubit.setDeadline(DateTime(2026, 10, 10, 17, 45));

        // Chỉ lưu phần ngày.
        verify(() => taskRepository.updateTaskDeadline(
              taskId: 't1',
              deadline: DateTime(2026, 10, 10),
            )).called(1);
        expect(cubit.state.status, TaskDetailStatus.saved);
        expect(cubit.state.message, 'Đã lưu deadline');
        await cubit.close();
      });
    }

    test('đổi deadline đã có sang ngày khác', () async {
      stubDeadline(() async {});
      final cubit =
          await buildStarted(task: buildTask(deadline: DateTime(2026, 10, 10)));

      await cubit.setDeadline(DateTime(2026, 10, 20));

      verify(() => taskRepository.updateTaskDeadline(
            taskId: 't1',
            deadline: DateTime(2026, 10, 20),
          )).called(1);
      await cubit.close();
    });

    test('hôm nay là deadline hợp lệ', () async {
      stubDeadline(() async {});
      final cubit = await buildStarted();
      await cubit.setDeadline(DateTime(2026, 10, 6));
      expect(cubit.state.status, TaskDetailStatus.saved);
      await cubit.close();
    });

    test('xoá deadline (null)', () async {
      stubDeadline(() async {});
      final cubit =
          await buildStarted(task: buildTask(deadline: DateTime(2026, 10, 10)));

      await cubit.setDeadline(null);

      verify(() => taskRepository.updateTaskDeadline(taskId: 't1', deadline: null))
          .called(1);
      expect(cubit.state.message, 'Đã xoá deadline');
      await cubit.close();
    });

    test('task chưa có deadline + setDeadline(null) → không crash, không ghi',
        () async {
      final cubit = await buildStarted();
      await cubit.setDeadline(null);
      expect(cubit.state.status, TaskDetailStatus.idle);
      verifyNever(() => taskRepository.updateTaskDeadline(
            taskId: any(named: 'taskId'),
            deadline: any(named: 'deadline'),
          ));
      await cubit.close();
    });

    test('deadline trong quá khứ bị từ chối', () async {
      final cubit = await buildStarted();
      await cubit.setDeadline(DateTime(2026, 10, 5));
      expect(cubit.state.status, TaskDetailStatus.failure);
      expect(cubit.state.message, 'Deadline không được ở trong quá khứ.');
      verifyNever(() => taskRepository.updateTaskDeadline(
            taskId: any(named: 'taskId'),
            deadline: any(named: 'deadline'),
          ));
      await cubit.close();
    });

    test('user không phải thành viên project (role null) bị từ chối', () async {
      final cubit = await buildStarted(role: null);
      await cubit.setDeadline(DateTime(2026, 10, 10));
      expect(cubit.state.status, TaskDetailStatus.failure);
      verifyNever(() => taskRepository.updateTaskDeadline(
            taskId: any(named: 'taskId'),
            deadline: any(named: 'deadline'),
          ));
      await cubit.close();
    });

    test('Firestore lỗi → failure, deadline cũ giữ nguyên', () async {
      stubDeadline(() async => throw Exception('Lỗi kết nối mạng.'));
      final cubit =
          await buildStarted(task: buildTask(deadline: DateTime(2026, 10, 10)));

      await cubit.setDeadline(DateTime(2026, 10, 20));

      expect(cubit.state.status, TaskDetailStatus.failure);
      expect(cubit.state.message, 'Lỗi kết nối mạng.');
      expect(cubit.state.task!.deadline, DateTime(2026, 10, 10));
      await cubit.close();
    });
  });

  test('memberDisplayName: họ tên → email → uid', () {
    expect(memberDisplayName(members.first), 'Phúc');
    final noProfile = ProjectMemberDisplay(
      membership: members.first.membership,
      user: null,
    );
    expect(memberDisplayName(noProfile), 'u-phuc');
  });
}
