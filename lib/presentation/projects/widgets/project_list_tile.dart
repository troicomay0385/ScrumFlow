import 'package:flutter/material.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/project_summary.dart';
import '../../project_members/widgets/role_badge.dart';

class ProjectListTile extends StatelessWidget {
  final ProjectSummary summary;
  final VoidCallback onTap;

  const ProjectListTile({super.key, required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final project = summary.project;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const CircleAvatar(
          backgroundColor: AppColors.primary,
          child: Icon(Icons.folder, color: Colors.white),
        ),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          project.description.isEmpty ? 'Chưa có mô tả' : project.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: RoleBadge(role: summary.myRole),
        onTap: onTap,
      ),
    );
  }
}
