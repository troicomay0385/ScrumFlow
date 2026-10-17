import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/datasources/firebase_auth_datasource.dart';
import 'package:scrumflow/data/datasources/firestore_datasource.dart';
import 'package:scrumflow/data/datasources/work_log_datasource.dart';
import 'package:scrumflow/data/models/task_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/models/work_log_model.dart';
import 'package:scrumflow/data/repositories/project_member_repository.dart';
import 'package:scrumflow/data/repositories/task_repository.dart';
import 'package:scrumflow/data/repositories/work_log_repository_impl.dart';

class MockWorkLogDataSource extends Mock implements WorkLogDataSource {}

class MockProjectMemberRepository extends Mock
    implements ProjectMemberRepository {}

class MockTaskRepository extends Mock implements TaskRepository {}

class MockFirestoreDataSource extends Mock implements FirestoreDataSource {}

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockUser extends Mock implements User {}

class FakeWorkLogModel extends Fake implements WorkLogModel {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWorkLogModel());
  });

  const uid = 'uid-test';
  const projectId = 'proj-1';
  const taskId = 'task-1';
  final now = DateTime(2026, 10, 17, 10, 0);

  final taskWithProject = TaskModel(
    id: taskId,
    storyId: 'story-1',
    title: 'Task Đã Gắn Project',
    description: '',
    status: 'To Do',
    projectId: projectId,
    loggedHours: 1.5,
    createdAt: now,
    updatedAt: now,
  );

  final taskWithoutProject = TaskModel(
    id: taskId,
    storyId: 'story-1',
    title: 'Task Chưa Gắn Project',
    description: '',
    status: 'To Do',
    projectId: null,
    loggedHours: 0.0,
    createdAt: now,
    updatedAt: now,
  );

  late MockWorkLogDataSource dataSource;
  late MockProjectMemberRepository memberRepository;
  late MockTaskRepository taskRepository;
  late MockFirestoreDataSource userDataSource;
  late MockFirebaseAuthDataSource authDataSource;
  late MockUser user;
  late WorkLogRepositoryImpl repository;

  setUp(() {
    dataSource = MockWorkLogDataSource();
    memberRepository = MockProjectMemberRepository();
    taskRepository = MockTaskRepository();
    userDataSource = MockFirestoreDataSource();
    authDataSource = MockFirebaseAuthDataSource();
    user = MockUser();

    when(() => user.uid).thenReturn(uid);
    when(() => user.displayName).thenReturn('Member User');
    when(() => user.email).thenReturn('member@scrumflow.com');
    when(() => authDataSource.currentUser).thenReturn(user);

    when(() => userDataSource.getUserProfile(uid)).thenAnswer(
      (_) async => UserModel(
        id: uid,
        email: 'member@scrumflow.com',
        fullName: 'Member FullName',
        createdAt: DateTime(2026, 1, 1),
        loginProvider: 'email',
      ),
    );

    when(() => memberRepository.getCurrentUserRole(projectId))
        .thenAnswer((_) async => ProjectRole.member);

    when(() => taskRepository.attachProject(
          taskId: any(named: 'taskId'),
          projectId: any(named: 'projectId'),
        )).thenAnswer((_) async {});

    when(() => dataSource.addWorkLog(any())).thenAnswer((_) async {});

    repository = WorkLogRepositoryImpl(
      dataSource: dataSource,
      memberRepository: memberRepository,
      taskRepository: taskRepository,
      userDataSource: userDataSource,
      authDataSource: authDataSource,
      now: () => now,
    );
  });

  group('WorkLogRepositoryImpl', () {
    test('streamWorkLogs delegates to dataSource', () {
      final logs = [
        WorkLogModel(
          id: 'log-1',
          taskId: taskId,
          projectId: projectId,
          userId: uid,
          userName: 'Member User',
          hours: 2.0,
          note: 'Phát triển backend',
          workDate: DateTime(2026, 10, 16),
          createdAt: now,
        ),
      ];
      when(() => dataSource.streamWorkLogs(taskId))
          .thenAnswer((_) => Stream.value(logs));

      expect(repository.streamWorkLogs(taskId), emits(logs));
    });

    test('streamWorkLogs maps FirebaseException code', () {
      when(() => dataSource.streamWorkLogs(taskId)).thenAnswer((_) =>
          Stream.error(
              fs.FirebaseException(plugin: 'firestore', code: 'permission-denied')));

      expect(
        repository.streamWorkLogs(taskId),
        emitsError(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Không có quyền truy cập dữ liệu'),
        )),
      );
    });

    test('logWork throws if user is not signed in', () async {
      when(() => authDataSource.currentUser).thenReturn(null);

      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 2.0,
          note: 'Ghi chú',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('đăng nhập'),
        )),
      );
    });

    test('logWork throws if hours is not valid', () async {
      // <= 0
      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 0.0,
          note: 'Ghi chú',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('lớn hơn 0'),
        )),
      );

      // > 24
      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 25.0,
          note: 'Ghi chú',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('24 giờ'),
        )),
      );

      // not multiple of 0.25
      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 1.1,
          note: 'Ghi chú',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('0.25'),
        )),
      );
    });

    test('logWork throws if workDate is in the future', () async {
      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 2.0,
          note: 'Ghi chú',
          workDate: now.add(const Duration(days: 2)),
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('tương lai'),
        )),
      );
    });

    test('logWork throws if user is not project member', () async {
      when(() => memberRepository.getCurrentUserRole(projectId))
          .thenAnswer((_) async => null);

      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 2.0,
          note: 'Ghi chú',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('thành viên của dự án'),
        )),
      );
    });

    test('logWork succeeds when task has projectId, attachProject is NOT called', () async {
      await repository.logWork(
        task: taskWithProject,
        projectId: projectId,
        hours: 2.5,
        note: 'Code api',
        workDate: DateTime(2026, 10, 16),
      );

      verifyNever(() => taskRepository.attachProject(
            taskId: any(named: 'taskId'),
            projectId: any(named: 'projectId'),
          ));

      verify(() => dataSource.addWorkLog(any(that: isA<WorkLogModel>()
          .having((l) => l.taskId, 'taskId', taskId)
          .having((l) => l.projectId, 'projectId', projectId)
          .having((l) => l.userId, 'userId', uid)
          .having((l) => l.userName, 'userName', 'Member FullName')
          .having((l) => l.hours, 'hours', 2.5)
          .having((l) => l.note, 'note', 'Code api')))).called(1);
    });

    test('logWork calls attachProject before addWorkLog when task lacks projectId', () async {
      await repository.logWork(
        task: taskWithoutProject,
        projectId: projectId,
        hours: 1.75,
        note: 'Setup db',
        workDate: now,
      );

      verify(() => taskRepository.attachProject(
            taskId: taskId,
            projectId: projectId,
          )).called(1);

      verify(() => dataSource.addWorkLog(any())).called(1);
    });

    test('logWork maps FirebaseException to friendly message', () async {
      when(() => dataSource.addWorkLog(any())).thenThrow(
        fs.FirebaseException(plugin: 'firestore', code: 'permission-denied'),
      );

      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 1.0,
          note: 'Test',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Không có quyền truy cập dữ liệu'),
        )),
      );
    });

    test('logWork maps TimeoutException to friendly message', () async {
      when(() => dataSource.addWorkLog(any()))
          .thenThrow(TimeoutException('Request timed out'));

      expect(
        () => repository.logWork(
          task: taskWithProject,
          projectId: projectId,
          hours: 1.0,
          note: 'Test',
          workDate: now,
        ),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('Máy chủ phản hồi quá lâu'),
        )),
      );
    });
  });
}
