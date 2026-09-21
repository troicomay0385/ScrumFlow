import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/authorization/permission.dart';
import '../../../app/authorization/project_role.dart';
import '../../../app/authorization/role_permissions.dart';
import '../../../app/constants/app_colors.dart';
import '../../../app/routes/app_routes.dart';
import '../../../data/models/project_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/project_repository.dart';

/// Chi tiết project — hiện tại chỉ hiển thị thông tin cơ bản + điểm vào
/// "Quản lý thành viên". Backlog/Sprint/Task sẽ bổ sung ở các User Story
/// sau (không thuộc phạm vi tính năng phân quyền này).
///
/// Dùng [StreamBuilder] gọi thẳng Repository (không qua Bloc riêng) vì
/// đây chỉ là nav-guard hiển thị/ẩn nút — không có business logic hay
/// Firestore query nằm trong widget (mọi thứ vẫn đi qua Repository, và
/// điều kiện quyền vẫn tính bằng [hasPermission] dùng chung toàn app).
/// Việc ẨN nút này chỉ là UX — quyền truy cập thật sự được
/// [ProjectMembersScreen]/Bloc và Firestore Security Rules kiểm tra lại.
class ProjectDetailScreen extends StatelessWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final projectRepository = context.read<ProjectRepository>();
    final memberRepository = context.read<ProjectMemberRepository>();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiết Project')),
      body: StreamBuilder<ProjectModel?>(
        stream: projectRepository.streamProject(projectId),
        builder: (context, projectSnapshot) {
          if (projectSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final project = projectSnapshot.data;
          if (project == null) {
            return const Center(child: Text('Project không tồn tại hoặc đã bị xoá'));
          }

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(project.name,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text(
                  project.description.isEmpty
                      ? 'Chưa có mô tả'
                      : project.description,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),
                StreamBuilder<ProjectRole?>(
                  stream: memberRepository.streamCurrentUserRole(projectId),
                  builder: (context, roleSnapshot) {
                    final role = roleSnapshot.data;
                    if (!hasPermission(role, Permission.viewMembers)) {
                      return const SizedBox.shrink();
                    }
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.group, color: AppColors.primary),
                        title: const Text('Quản lý thành viên'),
                        subtitle: const Text('Xem & phân quyền PO / SM / Member'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.projectMembers,
                          arguments: projectId,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
