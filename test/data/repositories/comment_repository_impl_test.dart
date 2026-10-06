import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:scrumflow/app/authorization/project_role.dart';
import 'package:scrumflow/data/datasources/comment_datasource.dart';
import 'package:scrumflow/data/datasources/firebase_auth_datasource.dart';
import 'package:scrumflow/data/datasources/firestore_datasource.dart';
import 'package:scrumflow/data/datasources/project_member_datasource.dart';
import 'package:scrumflow/data/models/comment_model.dart';
import 'package:scrumflow/data/models/project_member_model.dart';
import 'package:scrumflow/data/models/user_model.dart';
import 'package:scrumflow/data/repositories/comment_repository_impl.dart';

class MockCommentDataSource extends Mock implements CommentDataSource {}

class MockProjectMemberDataSource extends Mock
    implements ProjectMemberDataSource {}

class MockFirestoreDataSource extends Mock implements FirestoreDataSource {}

class MockFirebaseAuthDataSource extends Mock
    implements FirebaseAuthDataSource {}

class MockUser extends Mock implements User {}

void main() {
  const uid = 'uid-hieu';
  const projectId = 'p1';
  const storyTarget = CommentTarget.story(projectId: projectId, storyId: 's1');
  const taskTarget = CommentTarget.task(projectId: projectId, taskId: 't1');
  final now = DateTime(2026, 10, 6, 10);

  late MockCommentDataSource dataSource;
  late MockProjectMemberDataSource memberDataSource;
  late MockFirestoreDataSource userDataSource;
  late MockFirebaseAuthDataSource authDataSource;
  late MockUser user;
  late CommentRepositoryImpl repository;

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

  CommentModel capturedComment() => verify(
        () => dataSource.addComment(any(), captureAny()),
      ).captured.single as CommentModel;

  setUpAll(() {
    registerFallbackValue(storyTarget);
    registerFallbackValue(CommentModel(
      id: '',
      projectId: projectId,
      authorId: uid,
      authorName: '',
      content: '',
      createdAt: now,
    ));
  });

  setUp(() {
    dataSource = MockCommentDataSource();
    memberDataSource = MockProjectMemberDataSource();
    userDataSource = MockFirestoreDataSource();
    authDataSource = MockFirebaseAuthDataSource();
    user = MockUser();
    when(() => user.uid).thenReturn(uid);
    when(() => user.displayName).thenReturn(null);
    when(() => user.email).thenReturn('hieu.dev@scrumflow.com');
    when(() => authDataSource.currentUser).thenReturn(user);
    when(() => userDataSource.getUserProfile(uid)).thenAnswer(
      (_) async => UserModel(
        id: uid,
        fullName: 'Nguyễn Hiếu',
        email: 'hieu.dev@scrumflow.com',
        createdAt: DateTime(2026, 1, 1),
        loginProvider: 'email',
      ),
    );
    when(() => dataSource.addComment(any(), any())).thenAnswer((_) async {});
    repository = CommentRepositoryImpl(
      dataSource: dataSource,
      memberDataSource: memberDataSource,
      userDataSource: userDataSource,
      authDataSource: authDataSource,
      now: () => now,
    );
  });

  group('addComment — phân quyền', () {
    for (final role in ProjectRole.values) {
      test('${role.toFirestoreValue()} được bình luận', () async {
        givenRole(role);
        await repository.addComment(target: storyTarget, content: 'Xong UI');
        verify(() => dataSource.addComment(storyTarget, any())).called(1);
      });
    }

    test('user ngoài project không được bình luận', () async {
      givenRole(null);
      await expectLater(
        repository.addComment(target: storyTarget, content: 'Xong UI'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Chỉ thành viên của project mới được bình luận'))),
      );
      verifyNever(() => dataSource.addComment(any(), any()));
    });

    test('chưa đăng nhập không được bình luận', () async {
      when(() => authDataSource.currentUser).thenReturn(null);
      await expectLater(
        repository.addComment(target: storyTarget, content: 'Xong UI'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Bạn cần đăng nhập'))),
      );
      verifyNever(() => dataSource.addComment(any(), any()));
    });
  });

  group('addComment — nội dung & tác giả', () {
    setUp(() => givenRole(ProjectRole.member));

    test('từ chối bình luận rỗng / toàn khoảng trắng, không gọi Firestore',
        () async {
      for (final content in ['', '    ', '\n\t ']) {
        await expectLater(
          repository.addComment(target: taskTarget, content: content),
          throwsA(isA<Exception>().having((e) => e.toString(), 'message',
              contains('Vui lòng nhập nội dung bình luận'))),
        );
      }
      verifyNever(() => dataSource.addComment(any(), any()));
      verifyNever(() => memberDataSource.getMembership(
            projectId: any(named: 'projectId'),
            userId: any(named: 'userId'),
          ));
    });

    test('US-045: comment story có author là user đang đăng nhập + storyId',
        () async {
      await repository.addComment(
          target: storyTarget, content: '  Backend Firebase đã xong.  ');

      final comment = capturedComment();
      expect(comment.authorId, uid);
      expect(comment.authorName, 'Nguyễn Hiếu');
      expect(comment.content, 'Backend Firebase đã xong.');
      expect(comment.projectId, projectId);
      expect(comment.storyId, 's1');
      expect(comment.taskId, isNull);
      expect(comment.createdAt, now);
    });

    test('US-046: comment task gắn đúng taskId, không lẫn sang story',
        () async {
      await repository.addComment(
          target: taskTarget, content: 'Nhớ kiểm tra validation.');

      verify(() => dataSource.addComment(taskTarget, any())).called(1);
      verifyNever(() => dataSource.addComment(storyTarget, any()));
    });

    test('comment task tham chiếu taskId và projectId', () async {
      await repository.addComment(target: taskTarget, content: 'Đã xong UI');
      final comment = capturedComment();
      expect(comment.taskId, 't1');
      expect(comment.storyId, isNull);
      expect(comment.projectId, projectId);
    });

    test('chưa có hồ sơ users/{uid} → dùng email của tài khoản làm tên',
        () async {
      when(() => userDataSource.getUserProfile(uid))
          .thenAnswer((_) async => null);
      await repository.addComment(target: taskTarget, content: 'Hi');
      expect(capturedComment().authorName, 'hieu.dev@scrumflow.com');
    });
  });

  group('addComment — lỗi Firebase', () {
    setUp(() => givenRole(ProjectRole.member));

    test('permission-denied → thông báo tiếng Việt', () async {
      when(() => dataSource.addComment(any(), any())).thenThrow(
        fs.FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
      );
      await expectLater(
        repository.addComment(target: taskTarget, content: 'Hi'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Không có quyền truy cập dữ liệu'))),
      );
    });

    test('mất mạng (unavailable / timeout) → thông báo tiếng Việt', () async {
      when(() => dataSource.addComment(any(), any())).thenThrow(
        fs.FirebaseException(plugin: 'cloud_firestore', code: 'unavailable'),
      );
      await expectLater(
        repository.addComment(target: taskTarget, content: 'Hi'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('tạm thời không khả dụng'))),
      );

      when(() => dataSource.addComment(any(), any()))
          .thenThrow(TimeoutException('timeout'));
      await expectLater(
        repository.addComment(target: taskTarget, content: 'Hi'),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Máy chủ phản hồi quá lâu'))),
      );
    });
  });

  group('streamComments', () {
    test('chuyển tiếp danh sách bình luận của đúng target', () async {
      final comment = CommentModel(
        id: 'c1',
        projectId: projectId,
        taskId: 't1',
        authorId: uid,
        authorName: 'Nguyễn Hiếu',
        content: 'Đã kiểm tra Firebase.',
        createdAt: now,
      );
      when(() => dataSource.streamComments(taskTarget))
          .thenAnswer((_) => Stream.value([comment]));

      expect(await repository.streamComments(taskTarget).first, [comment]);
      verifyNever(() => dataSource.streamComments(storyTarget));
    });

    test('lỗi Firebase trên stream → thông báo tiếng Việt', () async {
      when(() => dataSource.streamComments(storyTarget)).thenAnswer(
        (_) => Stream.error(fs.FirebaseException(
            plugin: 'cloud_firestore', code: 'permission-denied')),
      );
      await expectLater(
        repository.streamComments(storyTarget).first,
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('Không có quyền truy cập dữ liệu'))),
      );
    });
  });
}
