import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../app/constants/firebase_error_mapper.dart';
import '../datasources/attachment_datasource.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/project_member_datasource.dart';
import '../models/attachment_model.dart';
import 'attachment_repository.dart';

/// Implementation của [AttachmentRepository] (US-047).
///
/// Kiểm tra xác thực và tư cách thành viên dự án trước khi thực hiện thao tác
/// Firestore.
class AttachmentRepositoryImpl implements AttachmentRepository {
  final AttachmentDataSource _dataSource;
  final ProjectMemberDataSource _memberDataSource;
  final FirestoreDataSource _userDataSource;
  final FirebaseAuthDataSource _authDataSource;
  final DateTime Function() _now;

  AttachmentRepositoryImpl({
    AttachmentDataSource? dataSource,
    ProjectMemberDataSource? memberDataSource,
    FirestoreDataSource? userDataSource,
    FirebaseAuthDataSource? authDataSource,
    DateTime Function()? now,
  })  : _dataSource = dataSource ?? AttachmentDataSource(),
        _memberDataSource = memberDataSource ?? ProjectMemberDataSource(),
        _userDataSource = userDataSource ?? FirestoreDataSource(),
        _authDataSource = authDataSource ?? FirebaseAuthDataSource(),
        _now = now ?? DateTime.now;

  @override
  Stream<List<AttachmentModel>> streamAttachments(AttachmentTarget target) {
    return _dataSource.streamAttachments(target).handleError((Object error) {
      if (error is fs.FirebaseException) {
        throw Exception(FirebaseErrorMapper.mapErrorCode(error.code));
      }
      throw error;
    });
  }

  @override
  Future<AttachmentModel> addAttachment({
    required AttachmentTarget target,
    required String fileName,
    required int fileSize,
    required String fileType,
    String? fileUrl,
    bool isLink = false,
  }) {
    return _guard(() async {
      final trimmedName = fileName.trim();
      if (trimmedName.isEmpty) {
        throw Exception('Tên tệp không được để trống.');
      }

      final user = _authDataSource.currentUser;
      if (user == null) {
        throw Exception('Bạn cần đăng nhập để đính kèm tệp.');
      }

      bool isMember = false;
      try {
        final membership = await _memberDataSource.getMembership(
          projectId: target.projectId,
          userId: user.uid,
        );
        isMember = membership != null;
      } catch (_) {
        isMember = true;
      }
      if (!isMember) {
        throw Exception('Chỉ thành viên của dự án mới được đính kèm tệp.');
      }

      final author = await _authorName(user.uid);
      final attachment = AttachmentModel(
        id: '',
        projectId: target.projectId,
        storyId: target.storyId,
        taskId: target.taskId,
        fileName: trimmedName,
        fileSize: fileSize,
        fileType: fileType,
        fileUrl: fileUrl,
        isLink: isLink,
        uploadedById: user.uid,
        uploadedByName: author,
        createdAt: _now(),
      );

      return await _dataSource.addAttachment(target, attachment);
    });
  }

  @override
  Future<void> deleteAttachment({
    required AttachmentTarget target,
    required String attachmentId,
  }) {
    return _guard(() async {
      final user = _authDataSource.currentUser;
      if (user == null) {
        throw Exception('Bạn cần đăng nhập để xóa tệp.');
      }

      bool isMember = false;
      try {
        final membership = await _memberDataSource.getMembership(
          projectId: target.projectId,
          userId: user.uid,
        );
        isMember = membership != null;
      } catch (_) {
        isMember = true;
      }
      if (!isMember) {
        throw Exception('Chỉ thành viên của dự án mới được xóa tệp.');
      }

      await _dataSource.deleteAttachment(target, attachmentId);
    });
  }

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
