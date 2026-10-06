import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../app/authorization/permission.dart';
import '../../app/authorization/role_permissions.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../../app/utils/comment_validator.dart';
import '../datasources/comment_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/project_member_datasource.dart';
import '../models/comment_model.dart';
import 'comment_repository.dart';

/// Implementation của [CommentRepository].
///
/// Kiểm tra nội dung + `Permission.comment` TRƯỚC khi gọi Firestore — lớp
/// bảo vệ thứ 2 bên cạnh Firestore Security Rules (cùng cách làm với
/// `BacklogRepositoryImpl`).
class CommentRepositoryImpl implements CommentRepository {
  final CommentDataSource _dataSource;
  final ProjectMemberDataSource _memberDataSource;
  final FirestoreDataSource _userDataSource;
  final FirebaseAuthDataSource _authDataSource;
  final DateTime Function() _now;

  CommentRepositoryImpl({
    CommentDataSource? dataSource,
    ProjectMemberDataSource? memberDataSource,
    FirestoreDataSource? userDataSource,
    FirebaseAuthDataSource? authDataSource,
    DateTime Function()? now,
  })  : _dataSource = dataSource ?? CommentDataSource(),
        _memberDataSource = memberDataSource ?? ProjectMemberDataSource(),
        _userDataSource = userDataSource ?? FirestoreDataSource(),
        _authDataSource = authDataSource ?? FirebaseAuthDataSource(),
        _now = now ?? DateTime.now;

  @override
  Stream<List<CommentModel>> streamComments(CommentTarget target) {
    return _dataSource.streamComments(target).handleError((Object error) {
      if (error is fs.FirebaseException) {
        throw Exception(FirebaseErrorMapper.mapErrorCode(error.code));
      }
      throw error;
    });
  }

  @override
  Future<void> addComment({
    required CommentTarget target,
    required String content,
  }) {
    return _guard(() async {
      final validationError = CommentValidator.validate(content);
      if (validationError != null) throw Exception(validationError);

      final user = _authDataSource.currentUser;
      if (user == null) {
        throw Exception('Bạn cần đăng nhập để bình luận.');
      }

      final membership = await _memberDataSource.getMembership(
        projectId: target.projectId,
        userId: user.uid,
      );
      if (membership == null ||
          !hasPermission(membership.role, Permission.comment)) {
        throw Exception('Chỉ thành viên của project mới được bình luận.');
      }

      await _dataSource.addComment(
        target,
        CommentModel(
          id: '',
          projectId: target.projectId,
          storyId: target.storyId,
          taskId: target.taskId,
          authorId: user.uid,
          authorName: await _authorName(user.uid),
          content: content.trim(),
          createdAt: _now(),
        ),
      );
    });
  }

  /// Tên hiển thị của người bình luận: hồ sơ `users/{uid}` → tên/email trên
  /// tài khoản Firebase Auth.
  Future<String> _authorName(String uid) async {
    final profile = await _userDataSource.getUserProfile(uid);
    final candidates = [
      profile?.fullName,
      _authDataSource.currentUser?.displayName,
      profile?.email,
      _authDataSource.currentUser?.email,
    ];
    for (final name in candidates) {
      if (name != null && name.trim().isNotEmpty) return name.trim();
    }
    return 'Thành viên';
  }

  /// Chuyển lỗi Firebase/timeout sang thông báo tiếng Việt qua
  /// [FirebaseErrorMapper] — UI không bao giờ thấy lỗi kỹ thuật thô.
  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on fs.FirebaseException catch (e) {
      throw Exception(FirebaseErrorMapper.mapErrorCode(e.code));
    } on TimeoutException {
      throw Exception(FirebaseErrorMapper.mapErrorCode('deadline-exceeded'));
    }
  }
}
