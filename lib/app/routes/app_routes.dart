import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/task_model.dart';
import '../../data/repositories/task_repository.dart';
import '../../presentation/auth/screens/login_screen.dart';
import '../../presentation/auth/screens/register_screen.dart';
import '../../presentation/home/screens/home_screen.dart';
import '../../presentation/projects/screens/create_project_screen.dart';
import '../../presentation/projects/screens/project_detail_screen.dart';
import '../../presentation/project_members/screens/project_members_screen.dart';
import '../../presentation/tasks/screens/task_detail_screen.dart';
import 'app_page_transitions.dart';


/// Định nghĩa tên các route và hàm tạo route với animated transitions.
///
/// Phase 1 chỉ khai báo route names và hàm [generateRoute].
/// Các màn hình cụ thể (LoginScreen, RegisterScreen, HomeScreen)
/// sẽ được thêm trong Phase 2.
class AppRoutes {
  AppRoutes._();

  // ── Route names ────────────────────────────────────────────
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String createProject = '/projects/create';
  static const String projectDetail = '/projects/detail';
  static const String projectMembers = '/projects/members';

  /// Route mở Task Detail từ push notification.
  /// [arguments] = taskId (String).
  static const String taskDetail = '/tasks/detail';

  /// Tạo route với fade + slide transition dùng chung ([AppPageTransition]),
  /// giống hệt hiệu ứng của các `MaterialPageRoute` trong app (US-064).
  ///
  /// [page] — widget màn hình đích.
  /// [duration] — thời gian animation (mặc định 300ms).
  static PageRouteBuilder buildRoute({
    required Widget page,
    required RouteSettings settings,
    Duration duration = AppPageTransition.duration,
  }) {
    return PageRouteBuilder(
      settings: settings,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
          AppPageTransition.build(context, animation, child),
    );
  }

  /// Hàm tạo route cho ứng dụng.
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Route cần projectId nhưng bị mở thiếu `arguments` (vd. gõ thẳng URL
    // trên Web) → quay về Login thay vì crash khi ép kiểu null.
    final needsProjectId =
        settings.name == projectDetail || settings.name == projectMembers;
    if (needsProjectId && settings.arguments is! String) {
      return buildRoute(
        settings: const RouteSettings(name: login),
        page: const LoginScreen(),
      );
    }

    switch (settings.name) {
      // '/' được Flutter tự động resolve thêm vào ĐÁY navigation stack khi
      // initialRoute là named-route (vd. '/login'), kể cả khi app không bao
      // giờ chủ động điều hướng tới '/'. Nếu không xử lý, route này sẽ rơi
      // vào `default` (Route not found) và có thể lộ ra khi pop hết stack.
      case '/':
      case login:
        return buildRoute(
          settings: settings,
          page: const LoginScreen(),
        );
      case register:
        return buildRoute(
          settings: settings,
          page: const RegisterScreen(),
        );
      case home:
        return buildRoute(
          settings: settings,
          page: const HomeScreen(),
        );
      case createProject:
        return buildRoute(
          settings: settings,
          page: const CreateProjectScreen(),
        );
      case projectDetail:
        return buildRoute(
          settings: settings,
          page: ProjectDetailScreen(projectId: settings.arguments as String),
        );
      case projectMembers:
        return buildRoute(
          settings: settings,
          page: ProjectMembersScreen(projectId: settings.arguments as String),
        );
      case taskDetail:
        // arguments là taskId (String) — được đặt bởi NotificationService khi user bấm
        // vào BLOCKER_ALERT notification (background hoặc killed state).
        final taskId = settings.arguments is String
            ? settings.arguments as String
            : null;
        if (taskId == null) {
          return buildRoute(
            settings: const RouteSettings(name: home),
            page: const HomeScreen(),
          );
        }
        return buildRoute(
          settings: settings,
          page: _TaskDetailFromIdScreen(taskId: taskId),
        );
      default:
        return buildRoute(
          settings: settings,
          page: const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}

/// Widget trung gian: tải [TaskModel] từ Firestore theo [taskId] rồi
/// hiển thị [TaskDetailScreen]. Dùng khi điều hướng từ notification (chỉ có taskId).
class _TaskDetailFromIdScreen extends StatelessWidget {
  final String taskId;
  const _TaskDetailFromIdScreen({required this.taskId});

  @override
  Widget build(BuildContext context) {
    final taskRepository = RepositoryProvider.of<TaskRepository>(context, listen: false);

    return StreamBuilder<TaskModel?>(
      stream: taskRepository.streamTask(taskId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final task = snapshot.data;
        if (task == null) {
          return const Scaffold(
            body: Center(child: Text('Không tìm thấy Task.')),
          );
        }
        return TaskDetailScreen(task: task, projectId: task.projectId ?? '');
      },
    );
  }
}

