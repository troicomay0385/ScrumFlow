import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;

import '../../app/authorization/permission.dart';
import '../../app/authorization/role_permissions.dart';
import '../../app/constants/firebase_error_mapper.dart';
import '../../app/utils/work_log_validator.dart';
import '../datasources/firebase_auth_datasource.dart';
import '../datasources/firestore_datasource.dart';
import '../datasources/work_log_datasource.dart';
import '../models/task_model.dart';
import '../models/work_log_model.dart';
import 'project_member_repository.dart';
import 'task_repository.dart';
import 'work_log_repository.dart';

/// Implementation của [WorkLogRepository] (US-066).
///
/// Kiểm tra đăng nhập, validate dữ liệu, kiểm tra quyền thành viên dự án,
/// gắn projectId cho task cũ nếu thiếu và lưu qua [WorkLogDataSource].
class WorkLogRepositoryImpl implements WorkLogRepository {
  final WorkLogDataSource _dataSource;
  final ProjectMemberRepository _memberRepository;
  final TaskRepository _taskRepository;
  final FirestoreDataSource _userDataSource;
  final FirebaseAuthDataSource _authDataSource;
  final DateTime Function() _now;

  WorkLogRepositoryImpl({
    WorkLogDataSource? dataSource,
    required ProjectMemberRepository memberRepository,
    TaskRepository? taskRepository,
    FirestoreDataSource? userDataSource,
    FirebaseAuthDataSource? authDataSource,
    DateTime Function()? now,
  })  : _dataSource = dataSource ?? WorkLogDataSource(),
        // ignore: prefer_initializing_formals
        _memberRepository = memberRepository,
        _taskRepository = taskRepository ?? TaskRepository(),
        _userDataSource = userDataSource ?? FirestoreDataSource(),
        _authDataSource = authDataSource ?? FirebaseAuthDataSource(),
        _now = now ?? DateTime.now;

  @override
  Stream<List<WorkLogModel>> streamWorkLogs(String taskId) {
    return _dataSource.streamWorkLogs(taskId).handleError((Object error) {
      if (error is fs.FirebaseException) {
        throw Exception(FirebaseErrorMapper.mapErrorCode(error.code));
      }
      throw error;
    });
  }

  @override
  Future<void> logWork({
    required TaskModel task,
    required String projectId,
    required double hours,
    required String note,
    required DateTime workDate,
  }) {
    return _guard(() async {
      final user = _authDataSource.currentUser;
      if (user == null) {
        throw Exception('Bạn cần đăng nhập để ghi giờ làm việc.');
      }

      final hoursError = WorkLogValidator.validateHours(hours);
      if (hoursError != null) {
        throw Exception(hoursError);
      }

      final noteError = WorkLogValidator.validateNote(note);
      if (noteError != null) {
        throw Exception(noteError);
      }

      final dateError = WorkLogValidator.validateWorkDate(workDate, now: _now());
      if (dateError != null) {
        throw Exception(dateError);
      }

      final role = await _memberRepository.getCurrentUserRole(projectId);
      if (role == null || !hasPermission(role, Permission.logWork)) {
        throw Exception('Chỉ thành viên của dự án mới được ghi giờ làm việc.');
      }

      if (task.projectId == null || task.projectId!.isEmpty) {
        await _taskRepository.attachProject(
          taskId: task.id,
          projectId: projectId,
        );
      }

      final author = await _authorName(user.uid);
      final log = WorkLogModel(
        id: '',
        taskId: task.id,
        projectId: projectId,
        userId: user.uid,
        userName: author,
        hours: hours,
        note: note.trim(),
        workDate: workDate,
        createdAt: _now(),
      );

      await _dataSource.addWorkLog(log);
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
