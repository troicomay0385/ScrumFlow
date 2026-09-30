import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/datasources/backlog_datasource.dart';
import 'package:scrumflow/data/datasources/firebase_auth_datasource.dart';
import 'package:scrumflow/data/datasources/project_member_datasource.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/user_story_model.dart';
import 'package:scrumflow/data/repositories/backlog_repository_impl.dart';

class MockBacklogDataSource extends Mock implements BacklogDataSource {}

class MockProjectMemberDataSource extends Mock
    implements ProjectMemberDataSource {}

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockUser extends Mock implements User {}

UserStoryModel existingStory(String key) => UserStoryModel(
      id: 'doc-$key',
      projectId: 'project-1',
      storyKey: key,
      title: key,
      description: '',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    );

void main() {
  const uid = 'uid-123';
  const projectId = 'project-1';
  final now = DateTime(2026, 9, 29, 10);

  late MockBacklogDataSource dataSource;
  late MockProjectMemberDataSource memberDataSource;
  late MockFirebaseAuthDataSource authDataSource;
  late MockUser user;
  late BacklogRepositoryImpl repository;

  void givenRole(ProjectRole? role) {
    when(() => memberDataSource.getMembership(
          projectId: projectId,
          userId: uid,
        )).thenAnswer((_) async => role == null
        ? null
        : ProjectMemberModel(
            id: '${projectId}_$uid',
            projectId: projectId,
            userId: uid,
            role: role,
            createdBy: 'owner',
            createdAt: DateTime(2026, 1, 1),
            updatedAt: DateTime(2026, 1, 1),
          ));
  }

  Future<UserStoryModel> create() => repository.createUserStory(
        projectId: projectId,
        title: '  Đăng nhập Google  ',
        description: ' Mô tả ',
        priority: 'CAO',
        deadline: DateTime(2026, 10, 5),
      );

  setUpAll(() {
    registerFallbackValue(existingStory('US-000'));
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    dataSource = MockBacklogDataSource();
    memberDataSource = MockProjectMemberDataSource();
    authDataSource = MockFirebaseAuthDataSource();
    user = MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => authDataSource.currentUser).thenReturn(user);
    when(() => dataSource.getUserStories(projectId)).thenAnswer((_) async => [
          existingStory('US-004'),
          existingStory('US-056'),
          existingStory('US-010'),
        ]);
    when(() => dataSource.createUserStory(any(), any())).thenAnswer(
        (inv) async => (inv.positionalArguments[1] as UserStoryModel)
            .copyWith(id: 'new-doc'));

    repository = BacklogRepositoryImpl(
      dataSource: dataSource,
      memberDataSource: memberDataSource,
      authDataSource: authDataSource,
      now: () => now,
    );
  });

  group('createUserStory (US-010)', () {
    for (final role in [ProjectRole.po, ProjectRole.sm]) {
      test('${role.displayName} tạo được story với dữ liệu hệ thống đầy đủ',
          () async {
        givenRole(role);

        final created = await create();

        final captured = verify(() => dataSource.createUserStory(
              projectId,
              captureAny(),
            )).captured.single as UserStoryModel;
        expect(captured.projectId, projectId);
        expect(captured.storyKey, 'US-057');
        expect(captured.title, 'Đăng nhập Google');
        expect(captured.description, 'Mô tả');
        expect(captured.priority, 'CAO');
        expect(captured.status, 'To Do');
        expect(captured.tags, isEmpty);
        expect(captured.deadline, DateTime(2026, 10, 5));
        expect(captured.createdBy, uid);
        expect(captured.createdAt, now);
        expect(captured.updatedAt, now);
        expect(created.id, 'new-doc');
      });
    }

    test('MEMBER bị từ chối, không ghi Firestore', () async {
      givenRole(ProjectRole.member);

      await expectLater(create(), throwsA(isA<Exception>()));
      verifyNever(() => dataSource.createUserStory(any(), any()));
    });

    test('user không phải thành viên project bị từ chối', () async {
      givenRole(null);

      await expectLater(create(), throwsA(isA<Exception>()));
      verifyNever(() => dataSource.createUserStory(any(), any()));
    });

    test('chưa đăng nhập bị từ chối', () async {
      when(() => authDataSource.currentUser).thenReturn(null);

      await expectLater(
        create(),
        throwsA(predicate((e) => e.toString().contains('đăng nhập'))),
      );
    });

    test('FirebaseException permission-denied → thông báo tiếng Việt', () async {
      givenRole(ProjectRole.po);
      when(() => dataSource.createUserStory(any(), any())).thenThrow(
          FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'));

      await expectLater(
        create(),
        throwsA(predicate(
            (e) => e.toString().contains('Không có quyền truy cập dữ liệu'))),
      );
    });

    test('timeout khi mất mạng → thông báo tiếng Việt', () async {
      givenRole(ProjectRole.po);
      when(() => dataSource.createUserStory(any(), any()))
          .thenThrow(TimeoutException('slow'));

      await expectLater(
        create(),
        throwsA(predicate((e) => e.toString().contains('phản hồi quá lâu'))),
      );
    });
  });

  group('updateTags (US-014)', () {
    test('PO cập nhật RIÊNG field tags qua datasource.updateTags', () async {
      givenRole(ProjectRole.po);
      when(() => dataSource.updateTags(any(), any(), any(), any()))
          .thenAnswer((_) async {});

      await repository.updateTags(
        projectId: projectId,
        storyId: 'doc-1',
        tags: const ['Frontend', 'UI'],
      );

      verify(() => dataSource.updateTags(
            projectId,
            'doc-1',
            const ['Frontend', 'UI'],
            now,
          )).called(1);
      // Không dùng saveUserStory (set toàn bộ object) → không mất field khác.
      verifyNever(() => dataSource.saveUserStory(any(), any()));
    });

    test('MEMBER không được sửa tag', () async {
      givenRole(ProjectRole.member);

      await expectLater(
        repository.updateTags(
            projectId: projectId, storyId: 'doc-1', tags: const ['X']),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => dataSource.updateTags(any(), any(), any(), any()));
    });
  });

  group('deleteUserStory (US-012)', () {
    for (final role in [ProjectRole.po, ProjectRole.sm]) {
      test('${role.name.toUpperCase()} xóa User Story thành công', () async {
        givenRole(role);
        when(() => dataSource.deleteUserStory(projectId, 'doc-1'))
            .thenAnswer((_) async {});

        await repository.deleteUserStory(
          projectId: projectId,
          storyId: 'doc-1',
        );

        verify(() => dataSource.deleteUserStory(projectId, 'doc-1')).called(1);
      });
    }

    test('MEMBER không được quyền xóa User Story', () async {
      givenRole(ProjectRole.member);

      await expectLater(
        repository.deleteUserStory(projectId: projectId, storyId: 'doc-1'),
        throwsA(
          predicate<Exception>(
            (e) => e.toString().contains('Chỉ Product Owner hoặc Scrum Master'),
          ),
        ),
      );
      verifyNever(() => dataSource.deleteUserStory(any(), any()));
    });

    test('User ngoài dự án (role null) bị từ chối xóa User Story', () async {
      givenRole(null);

      await expectLater(
        repository.deleteUserStory(projectId: projectId, storyId: 'doc-1'),
        throwsA(isA<Exception>()),
      );
      verifyNever(() => dataSource.deleteUserStory(any(), any()));
    });
  });

  group('nextStoryKey', () {
    test('backlog trống → US-001', () {
      expect(BacklogRepositoryImpl.nextStoryKey(const []), 'US-001');
    });

    test('bỏ qua key sai định dạng, lấy số lớn nhất + 1', () {
      expect(
        BacklogRepositoryImpl.nextStoryKey([
          existingStory('US-009'),
          existingStory('ABC'),
          existingStory('US-120'),
        ]),
        'US-121',
      );
    });
  });
}
