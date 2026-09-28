import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../settings/widgets/security_settings_dialog.dart';
import '../bloc/backlog_bloc.dart';
import '../bloc/backlog_event.dart';
import '../bloc/backlog_state.dart';
import 'user_story_detail_screen.dart';

class BacklogListScreen extends StatelessWidget {
  final String projectId;
  final String projectName;

  const BacklogListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BacklogBloc()
        ..add(BacklogSubscriptionRequested(projectId)),
      child: _BacklogListView(
        projectId: projectId,
        projectName: projectName,
      ),
    );
  }
}

class _BacklogListView extends StatefulWidget {
  final String projectId;
  final String projectName;

  const _BacklogListView({
    required this.projectId,
    required this.projectName,
  });

  @override
  State<_BacklogListView> createState() => _BacklogListViewState();
}

class _BacklogListViewState extends State<_BacklogListView> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildPriorityBadge(String priority) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (priority.toUpperCase()) {
      case 'CAO':
      case 'HIGH':
      case 'URGENT':
        textColor = const Color(0xFFB91C1C);
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFECACA);
        break;
      case 'TB':
      case 'TRUNG BÌNH':
      case 'MEDIUM':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        break;
      default:
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: textColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            priority,
            style: GoogleFonts.plusJakartaSans(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color textColor;
    Color bgColor;
    Color borderColor;

    switch (status.toLowerCase()) {
      case 'done':
        textColor = const Color(0xFF047857);
        bgColor = const Color(0xFFD1FAE5);
        borderColor = const Color(0xFFA7F3D0);
        break;
      case 'in progress':
        textColor = const Color(0xFFB45309);
        bgColor = const Color(0xFFFEF3C7);
        borderColor = const Color(0xFFFDE68A);
        break;
      case 'rejected':
        textColor = const Color(0xFF991B1B);
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFFECACA);
        break;
      default: // To Do
        textColor = const Color(0xFF475569);
        bgColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFE2E8F0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 10,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildDueDateBadge(DateTime? dueDate) {
    if (dueDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;
    final isOverdue = dueDate.isBefore(now);
    final isUrgent = difference <= 2;

    Color color;
    Color bg;
    if (isOverdue) {
      color = const Color(0xFFB91C1C);
      bg = const Color(0xFFFEE2E2);
    } else if (isUrgent) {
      color = const Color(0xFFB45309);
      bg = const Color(0xFFFEF3C7);
    } else {
      color = const Color(0xFF475569);
      bg = const Color(0xFFF1F5F9);
    }

    final dayStr = '${dueDate.day.toString().padLeft(2, '0')}/${dueDate.month.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_outlined, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            isOverdue ? 'Quá hạn: $dayStr' : 'Hạn: $dayStr',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context, BacklogLoaded state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        String tempStatus = state.statusFilter;
        String tempPriority = state.priorityFilter;
        String tempTag = state.tagFilter;

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1F0F172A),
                    blurRadius: 24,
                    offset: Offset(0, -8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),

                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Bộ lọc Backlog',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  tempStatus = 'Tất cả';
                                  tempPriority = 'Tất cả';
                                  tempTag = 'Tất cả';
                                });
                              },
                              child: Text(
                                'Đặt lại',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              onPressed: () => Navigator.pop(bottomSheetContext),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, thickness: 1, color: AppColors.surfaceVariant),

                  // Filter Content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section 1: Trạng thái (Status)
                          Text(
                            'LỌC THEO TRẠNG THÁI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Tất cả', 'To Do', 'In Progress', 'Done', 'Rejected']
                                .map((status) {
                              final isSelected = tempStatus == status;
                              return ChoiceChip(
                                label: Text(status),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline.withValues(alpha: 0.15),
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => tempStatus = status);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Section 2: Mức độ ưu tiên (Priority)
                          Text(
                            'LỌC THEO MỨC ƯU TIÊN',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Tất cả', 'CAO', 'TB', 'THẤP'].map((priority) {
                              final isSelected = tempPriority == priority;
                              Color dotColor = Colors.grey;
                              if (priority == 'CAO') dotColor = const Color(0xFFB91C1C);
                              if (priority == 'TB') dotColor = const Color(0xFFB45309);
                              if (priority == 'THẤP') dotColor = const Color(0xFF475569);

                              return ChoiceChip(
                                avatar: priority == 'Tất cả'
                                    ? null
                                    : Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.white : dotColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                label: Text(priority),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline.withValues(alpha: 0.15),
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => tempPriority = priority);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Section 3: Tag / Nhãn
                          Text(
                            'LỌC THEO NHÃN / TAG',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Tất cả', ...state.availableTags].map((tag) {
                              final isSelected = tempTag == tag;
                              return ChoiceChip(
                                label: Text(tag),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: AppColors.canvas,
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.outline.withValues(alpha: 0.15),
                                ),
                                labelStyle: GoogleFonts.plusJakartaSans(
                                  color: isSelected ? Colors.white : AppColors.onSurfaceVariant,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                                  fontSize: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => tempTag = tag);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Apply Button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          final bloc = context.read<BacklogBloc>();
                          bloc.add(BacklogStatusFilterChanged(tempStatus));
                          bloc.add(BacklogPriorityFilterChanged(tempPriority));
                          bloc.add(BacklogTagFilterChanged(tempTag));
                          Navigator.pop(bottomSheetContext);
                        },
                        child: Text(
                          'Áp dụng bộ lọc',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Product Backlog',
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
        actions: [
          BlocBuilder<BacklogBloc, BacklogState>(
            builder: (context, state) {
              final isSeeding = state is BacklogLoaded && state.isSeeding;
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: isSeeding
                      ? null
                      : () {
                          context
                              .read<BacklogBloc>()
                              .add(BacklogSeedMockRequested(widget.projectId));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Đang nạp 8 User Stories mẫu và User ảo...'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: isSeeding
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Icons.bolt_rounded,
                          color: AppColors.primary, size: 18),
                  label: Text(
                    isSeeding ? 'Đang tạo...' : 'Nạp mẫu',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Cài đặt bảo mật & Vân tay',
            onPressed: () => SecuritySettingsDialog.show(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<BacklogBloc, BacklogState>(
        listener: (context, state) {
          if (state is BacklogError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is BacklogLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is BacklogLoaded) {
            final allStories = state.stories;

            if (allStories.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          size: 56,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Product Backlog đang trống',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bấm nút bên dưới để tự động nạp 8 User Stories mẫu của Sprint 1 & Sprint 2 kèm User ảo để kiểm thử tính năng.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppColors.onSurfaceVariant,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 3,
                        ),
                        onPressed: () {
                          context
                              .read<BacklogBloc>()
                              .add(BacklogSeedMockRequested(widget.projectId));
                        },
                        icon: const Icon(Icons.bolt_rounded, size: 20),
                        label: Text(
                          'Nạp 8 User Stories Mẫu',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredStories = state.filteredStories;
            final totalPoints =
                allStories.fold<int>(0, (sum, s) => sum + s.storyPoints);

            return Column(
              children: [
                // Top KPI Bar
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: AppColors.surface,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.format_list_bulleted_rounded,
                              size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Tổng cộng: ${allStories.length} User Stories',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.bolt_rounded,
                                size: 14, color: Color(0xFFB45309)),
                            const SizedBox(width: 4),
                            Text(
                              '$totalPoints SP',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFFB45309),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // US-007: Search Bar
                Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (query) {
                      context
                          .read<BacklogBloc>()
                          .add(BacklogSearchChanged(query));
                      setState(() {});
                    },
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Tìm theo mã US, tiêu đề, tag, assignee...',
                      hintStyle: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: AppColors.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18),
                              color: AppColors.onSurfaceVariant,
                              onPressed: () {
                                _searchController.clear();
                                context
                                    .read<BacklogBloc>()
                                    .add(const BacklogSearchChanged(''));
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: AppColors.canvas,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.outline.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ),

                // US-008 & US-009: Toolbar Filter & Sort
                Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: Row(
                    children: [
                      // Quick Filter Sheet Button
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(
                            color: state.activeFilterCount > 0
                                ? AppColors.primary
                                : AppColors.outline.withValues(alpha: 0.2),
                          ),
                          backgroundColor: state.activeFilterCount > 0
                              ? AppColors.primary.withValues(alpha: 0.08)
                              : Colors.transparent,
                        ),
                        onPressed: () => _showFilterBottomSheet(context, state),
                        icon: Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: state.activeFilterCount > 0
                              ? AppColors.primary
                              : AppColors.onSurfaceVariant,
                        ),
                        label: Row(
                          children: [
                            Text(
                              'Bộ lọc',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: state.activeFilterCount > 0
                                    ? AppColors.primary
                                    : AppColors.onSurface,
                              ),
                            ),
                            if (state.activeFilterCount > 0) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${state.activeFilterCount}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // US-009: Sort Dropdown Menu
                      Expanded(
                        child: Container(
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: AppColors.canvas,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.outline.withValues(alpha: 0.15),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<BacklogSortBy>(
                              value: state.sortBy,
                              isExpanded: true,
                              icon: const Icon(Icons.sort_rounded,
                                  size: 18, color: AppColors.primary),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurface,
                              ),
                              items: BacklogSortBy.values.map((sortOption) {
                                return DropdownMenuItem<BacklogSortBy>(
                                  value: sortOption,
                                  child: Text(
                                    sortOption.label,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              onChanged: (newSort) {
                                if (newSort != null) {
                                  context
                                      .read<BacklogBloc>()
                                      .add(BacklogSortChanged(newSort));
                                }
                              },
                            ),
                          ),
                        ),
                      ),

                      // Reset Filters button if any filter/search is active
                      if (state.hasActiveFilters) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Đặt lại toàn bộ bộ lọc',
                          icon: const Icon(Icons.refresh_rounded,
                              size: 20, color: AppColors.primary),
                          onPressed: () {
                            _searchController.clear();
                            context
                                .read<BacklogBloc>()
                                .add(const BacklogFilterResetRequested());
                            setState(() {});
                          },
                        ),
                      ],
                    ],
                  ),
                ),

                // Quick Status filter chips row
                Container(
                  color: AppColors.surface,
                  padding:
                      const EdgeInsets.only(left: 16, right: 16, bottom: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['Tất cả', 'To Do', 'In Progress', 'Done', 'Rejected']
                          .map((filter) {
                        final isSelected = state.statusFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            backgroundColor: AppColors.canvas,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.outline.withValues(alpha: 0.15),
                            ),
                            labelStyle: GoogleFonts.plusJakartaSans(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.onSurfaceVariant,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                context
                                    .read<BacklogBloc>()
                                    .add(BacklogStatusFilterChanged(filter));
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const Divider(
                    height: 1, thickness: 1, color: AppColors.surfaceVariant),

                // Result count badge
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hiển thị: ${filteredStories.length} / ${allStories.length} User Stories',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (state.hasActiveFilters)
                        Text(
                          'Đang áp dụng bộ lọc',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),

                // Stories List or Empty Search State
                Expanded(
                  child: filteredStories.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    color: AppColors.outline
                                        .withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.search_off_rounded,
                                    size: 48,
                                    color: AppColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Không tìm thấy User Story nào',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Thử tìm từ khóa khác hoặc xóa bộ lọc để xem toàn bộ danh mục backlog.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(
                                        color: AppColors.primary),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    _searchController.clear();
                                    context
                                        .read<BacklogBloc>()
                                        .add(const BacklogFilterResetRequested());
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 16),
                                  label: const Text('Đặt lại bộ lọc'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: filteredStories.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final story = filteredStories[index];

                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          UserStoryDetailScreen(story: story),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppColors.outline
                                          .withValues(alpha: 0.12),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color:
                                            Colors.black.withValues(alpha: 0.02),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Top row: Key, Priority, Status, DueDate
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: AppColors.canvas,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: AppColors.outline
                                                    .withValues(alpha: 0.15),
                                              ),
                                            ),
                                            child: Text(
                                              story.storyKey,
                                              style: GoogleFonts.jetBrainsMono(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 11,
                                                color:
                                                    AppColors.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          _buildPriorityBadge(story.priority),
                                          const SizedBox(width: 8),
                                          _buildDueDateBadge(story.dueDate),
                                          const Spacer(),
                                          _buildStatusBadge(story.status),
                                        ],
                                      ),
                                      const SizedBox(height: 12),

                                      // Title
                                      Text(
                                        story.title,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.onSurface,
                                          height: 1.3,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),

                                      // Description preview
                                      Text(
                                        story.description,
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          color: AppColors.onSurfaceVariant,
                                          height: 1.4,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      // Tags Row (US-008, US-014)
                                      if (story.tags.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: story.tags.map((tag) {
                                            return Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                tag,
                                                style:
                                                    GoogleFonts.plusJakartaSans(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                      ],
                                      const SizedBox(height: 14),

                                      // Bottom row: Points + Assignee
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF1F5F9),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.bolt_rounded,
                                                    size: 14,
                                                    color: Color(0xFFB45309)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${story.storyPoints} SP',
                                                  style:
                                                      GoogleFonts.jetBrainsMono(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                    color:
                                                        const Color(0xFF334155),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (story.assigneeName != null &&
                                              story.assigneeName!.isNotEmpty)
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: AppColors
                                                      .primaryContainer
                                                      .withValues(alpha: 0.15),
                                                  child: Text(
                                                    story.assigneeName!
                                                        .substring(0, 1)
                                                        .toUpperCase(),
                                                    style: GoogleFonts
                                                        .plusJakartaSans(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: AppColors.primary,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  story.assigneeName!,
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppColors.onSurface,
                                                  ),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          }

          if (state is BacklogError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF7ED),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        size: 56,
                        color: Color(0xFFEA580C),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Chưa đồng bộ được với Cloud Firestore',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Bạn vẫn có thể kiểm thử toàn diện US-005, US-006, US-007, US-008 và US-009 với 8 User Stories mẫu và 4 User ảo.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        context
                            .read<BacklogBloc>()
                            .add(BacklogSeedMockRequested(widget.projectId));
                      },
                      icon: const Icon(Icons.bolt_rounded),
                      label: Text(
                        'Nạp 8 User Stories Mẫu',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
