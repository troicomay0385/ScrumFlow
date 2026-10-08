import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/performance_score_model.dart';
import '../../../data/models/project_member_display.dart';
import '../../../data/models/task_model.dart';
import '../../../data/repositories/project_member_repository.dart';
import '../../../data/repositories/task_repository.dart';
import '../../../data/services/performance_score_service.dart';
import '../../project_members/widgets/role_badge.dart';

/// Màn hình Bảng thống kê hiệu suất từng thành viên (US-060).
/// Hiển thị KPI dự án, tỷ lệ đúng hạn, tải công việc và điểm hiệu suất tổng hợp.
class TeamPerformanceScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const TeamPerformanceScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<TeamPerformanceScreen> createState() => _TeamPerformanceScreenState();
}

class _TeamPerformanceScreenState extends State<TeamPerformanceScreen> {
  final _service = const PerformanceScoreService();
  int _sortIndex = 0; // 0: Điểm cao nhất, 1: Đúng hạn cao nhất, 2: Tải công việc nhiều nhất

  @override
  Widget build(BuildContext context) {
    final memberRepo = context.read<ProjectMemberRepository>();
    final taskRepo = context.read<TaskRepository>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu suất Đội ngũ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
              ),
            ),
            Text(
              widget.projectName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<List<ProjectMemberDisplay>>(
        stream: memberRepo.streamMembers(widget.projectId),
        builder: (context, memberSnapshot) {
          if (memberSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final members = memberSnapshot.data ?? [];
          if (members.isEmpty) {
            return _buildEmptyState('Dự án chưa có thành viên nào');
          }

          return StreamBuilder<List<TaskModel>>(
            stream: taskRepo.streamTasksByProject(widget.projectId),
            builder: (context, taskSnapshot) {
              final tasks = taskSnapshot.data ?? [];
              final scores = _service.calculateScores(
                members: members,
                allProjectTasks: tasks,
              );

              // Sắp xếp danh sách
              final sortedScores = List<MemberPerformanceScore>.from(scores);
              if (_sortIndex == 0) {
                sortedScores.sort((a, b) => b.finalScore.compareTo(a.finalScore));
              } else if (_sortIndex == 1) {
                sortedScores.sort((a, b) => b.onTimeRate.compareTo(a.onTimeRate));
              } else if (_sortIndex == 2) {
                sortedScores.sort((a, b) => b.inProgressTasks.compareTo(a.inProgressTasks));
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. KPI Overview Header
                  _buildKpiHeader(scores, tasks),
                  const SizedBox(height: 16),

                  // 2. Sort Selector
                  _buildSortSelector(),
                  const SizedBox(height: 16),

                  // 3. Member Performance Cards
                  ...sortedScores.map((score) => _buildMemberCard(score)),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildKpiHeader(List<MemberPerformanceScore> scores, List<TaskModel> tasks) {
    if (scores.isEmpty) return const SizedBox.shrink();

    final avgScore = (scores.map((s) => s.finalScore).reduce((a, b) => a + b) / scores.length * 100).round();
    final totalCompletedOnTime = scores.fold<int>(0, (sum, s) => sum + s.completedOnTimeTasks);
    final totalTasks = tasks.length;
    final totalInProgress = tasks.where((t) => t.status == 'In Progress').length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'Tổng Quan Hiệu Suất Toàn Đội',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildKpiItem(
                  title: 'Điểm Trung Bình',
                  value: '$avgScore%',
                  icon: Icons.speed_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _buildKpiItem(
                  title: 'Task Đúng Hạn',
                  value: '$totalCompletedOnTime',
                  icon: Icons.check_circle_outline_rounded,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withValues(alpha: 0.2)),
              Expanded(
                child: _buildKpiItem(
                  title: 'Đang Thực Hiện',
                  value: '$totalInProgress',
                  icon: Icons.timelapse_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKpiItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
            fontSize: 11,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSortSelector() {
    final options = ['Điểm cao nhất', 'Đúng hạn nhất', 'Việc nhiều nhất'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(options.length, (index) {
          final isSelected = _sortIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                options[index],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.onSurface,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? AppColors.primary : AppColors.outline.withValues(alpha: 0.15),
                ),
              ),
              onSelected: (_) => setState(() => _sortIndex = index),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildMemberCard(MemberPerformanceScore score) {
    final scorePercent = (score.finalScore * 100).round();
    final onTimePercent = (score.onTimeRate * 100).round();

    Color scoreColor;
    String scoreTier;
    if (scorePercent >= 85) {
      scoreColor = AppColors.success;
      scoreTier = 'Xuất sắc';
    } else if (scorePercent >= 70) {
      scoreColor = const Color(0xFF0284C7); // Blue
      scoreTier = 'Tốt';
    } else {
      scoreColor = AppColors.warning;
      scoreTier = 'Cần hỗ trợ';
    }

    final isOverloaded = score.inProgressTasks >= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: score.isTopPick
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.outline.withValues(alpha: 0.1),
          width: score.isTopPick ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row Header: Avatar + Tên + Role + Score Pill
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  score.userName.isNotEmpty ? score.userName[0].toUpperCase() : '?',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            score.userName,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        RoleBadge(role: score.role),
                      ],
                    ),
                    if (score.userEmail != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        score.userEmail!,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Điểm hiệu suất Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$scorePercent%',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      scoreTier,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Chỉ số: Tỷ lệ đúng hạn + Workload
          Row(
            children: [
              // 1. Tỷ lệ đúng hạn
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đúng hạn:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '$onTimePercent%',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: score.onTimeRate,
                        backgroundColor: AppColors.surfaceContainerLow,
                        valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),

              // 2. Tải công việc (Workload)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Đang xử lý:',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '${score.inProgressTasks}/5 task',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isOverloaded ? AppColors.error : AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (score.inProgressTasks / 5.0).clamp(0.0, 1.0),
                        backgroundColor: AppColors.surfaceContainerLow,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isOverloaded ? AppColors.error : const Color(0xFF0284C7),
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Đánh giá Trợ lý AI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  score.isTopPick ? Icons.auto_awesome_rounded : Icons.info_outline_rounded,
                  size: 14,
                  color: score.isTopPick ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    score.recommendationReason,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 48, color: AppColors.outline),
          const SizedBox(height: 12),
          Text(
            message,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
