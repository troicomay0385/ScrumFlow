import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/datasources/backlog_datasource.dart';
import 'package:scrumflow/data/datasources/firebase_auth_datasource.dart';
import 'package:scrumflow/data/datasources/project_member_datasource.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/repositories/story_repository_impl.dart';

class MockBacklogDataSource extends Mock implements BacklogDataSource {}

class MockProjectMemberDataSource extends Mock
    implements ProjectMemberDataSource {}

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockUser extends Mock implements User {}

void main() {
  const uid = 'uid-123';
  const projectId = 'project-1';
  const storyId = 'story-1';
  final fixedNow = DateTime(2026, 10, 8, 14, 0, 0);

  late MockBacklogDataSource dataSource;
  late MockProjectMemberDataSource memberDataSource;
  late MockFirebaseAuthDataSource authDataSource;
  late MockUser user;
  late StoryRepositoryImpl repository;

  void givenRole(ProjectRole? role) {
    when(() => memberDataSource.getMembership(
          projectId: projectId,
          userId: uid,
        )).thenAnswer(
      (_) async => role == null
          ? null
          : ProjectMemberModel(
              id: '${projectId}_$uid',
              projectId: projectId,
              userId: uid,
              role: role,
              createdBy: 'owner',
              createdAt: DateTime(2026, 9, 1),
              updatedAt: DateTime(2026, 9, 1),
            ),
    );
  }

  setUp(() {
    dataSource = MockBacklogDataSource();
    memberDataSource = MockProjectMemberDataSource();
    authDataSource = MockFirebaseAuthDataSource();
    user = MockUser();

    when(() => user.uid).thenReturn(uid);
    when(() => authDataSource.currentUser).thenReturn(user);

    when(() => dataSource.updateStoryStatus(
          projectId: any(named: 'projectId'),
          storyId: any(named: 'storyId'),
          status: any(named: 'status'),
          updatedAt: any(named: 'updatedAt'),
          completedAt: any(named: 'completedAt'),
          clearCompletedAt: any(named: 'clearCompletedAt'),
        )).thenAnswer((_) async {});

    repository = StoryRepositoryImpl(
      dataSource: dataSource,
      memberDataSource: memberDataSource,
      authDataSource: authDataSource,
      now: () => fixedNow,
    );
  });

  group('StoryRepositoryImpl - US-048', () {
    test('PO được phép cập nhật trạng thái sang "In Progress"', () async {
      givenRole(ProjectRole.po);

      await repository.updateStoryStatus(
        projectId: projectId,
        storyId: storyId,
        newStatus: 'In Progress',
      );

      verify(
        () => dataSource.updateStoryStatus(
          projectId: projectId,
          storyId: storyId,
          status: 'In Progress',
          updatedAt: fixedNow,
          completedAt: null,
          clearCompletedAt: true,
        ),
      ).called(1);
    });

    test('SM được phép cập nhật trạng thái sang "Done" và tự cập nhật completedAt', () async {
      givenRole(ProjectRole.sm);

      await repository.updateStoryStatus(
        projectId: projectId,
        storyId: storyId,
        newStatus: 'Done',
      );

      verify(
        () => dataSource.updateStoryStatus(
          projectId: projectId,
          storyId: storyId,
          status: 'Done',
          updatedAt: fixedNow,
          completedAt: fixedNow,
          clearCompletedAt: false,
        ),
      ).called(1);
    });

    test('PO cập nhật sang "Rejected" cũng tự động cập nhật completedAt', () async {
      givenRole(ProjectRole.po);

      await repository.updateStoryStatus(
        projectId: projectId,
        storyId: storyId,
        newStatus: 'Rejected',
      );

      verify(
        () => dataSource.updateStoryStatus(
          projectId: projectId,
          storyId: storyId,
          status: 'Rejected',
          updatedAt: fixedNow,
          completedAt: fixedNow,
          clearCompletedAt: false,
        ),
      ).called(1);
    });

    test('Member thông thường (MEMBER) bị từ chối với thông báo "Chỉ PO/SM mới có quyền cập nhật trạng thái"', () async {
      givenRole(ProjectRole.member);

      expect(
        () => repository.updateStoryStatus(
          projectId: projectId,
          storyId: storyId,
          newStatus: 'Done',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Chỉ PO/SM mới có quyền cập nhật trạng thái'),
          ),
        ),
      );

      verifyNever(
        () => dataSource.updateStoryStatus(
          projectId: any(named: 'projectId'),
          storyId: any(named: 'storyId'),
          status: any(named: 'status'),
          updatedAt: any(named: 'updatedAt'),
          completedAt: any(named: 'completedAt'),
          clearCompletedAt: any(named: 'clearCompletedAt'),
        ),
      );
    });

    test('Người dùng không phải thành viên dự án bị từ chối với thông báo "Chỉ PO/SM mới có quyền cập nhật trạng thái"', () async {
      givenRole(null);

      expect(
        () => repository.updateStoryStatus(
          projectId: projectId,
          storyId: storyId,
          newStatus: 'Done',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Chỉ PO/SM mới có quyền cập nhật trạng thái'),
          ),
        ),
      );
    });

    test('Chưa đăng nhập bị từ chối', () async {
      when(() => authDataSource.currentUser).thenReturn(null);

      expect(
        () => repository.updateStoryStatus(
          projectId: projectId,
          storyId: storyId,
          newStatus: 'Done',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Bạn cần đăng nhập'),
          ),
        ),
      );
    });
  });
}
