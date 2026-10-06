import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/standup_model.dart';
import '../../../data/repositories/standup_repository.dart';
import '../bloc/standup_bloc.dart';
import '../bloc/standup_event.dart';
import '../bloc/standup_state.dart';

class StandupHistoryScreen extends StatefulWidget {
  final String projectId;
  final String projectName;
  final String? sprintId; // If provided, load by sprintId by default

  const StandupHistoryScreen({
    super.key,
    required this.projectId,
    required this.projectName,
    this.sprintId,
  });

  @override
  State<StandupHistoryScreen> createState() => _StandupHistoryScreenState();
}

class _StandupHistoryScreenState extends State<StandupHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Fetch initial data
    if (widget.sprintId != null) {
      _fetchBySprint();
    } else {
      _fetchByDate(_selectedDate);
    }
  }

  void _fetchBySprint() {
    context.read<StandupBloc>().add(
          FetchStandupHistoryEvent(sprintId: widget.sprintId),
        );
  }

  void _fetchByDate(DateTime date) {
    // Get start of day and end of day for the selected date
    final startDate = DateTime(date.year, date.month, date.day);
    final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59);

    context.read<StandupBloc>().add(
          FetchStandupHistoryEvent(
            startDate: startDate,
            endDate: endDate,
          ),
        );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchByDate(_selectedDate);
    }
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
              'Lịch sử Stand-up',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w800,
                color: AppColors.onSurface,
                fontSize: 16,
              ),
            ),
            Text(
              widget.projectName,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w500,
                color: AppColors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onSurface),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 20),
            onPressed: () => _selectDate(context),
            tooltip: 'Chọn ngày',
          ),
          if (widget.sprintId != null)
            IconButton(
              icon: const Icon(Icons.sync_rounded, size: 22),
              onPressed: _fetchBySprint,
              tooltip: 'Tải theo Sprint',
            ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBanner(),
          Expanded(
            child: BlocBuilder<StandupBloc, StandupState>(
              builder: (context, state) {
                if (state is StandupHistoryLoading || state is StandupInitial) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                } else if (state is StandupHistoryFailure) {
                  return Center(
                    child: Text(
                      'Lỗi tải dữ liệu: ${state.error}',
                      style: GoogleFonts.plusJakartaSans(color: AppColors.error),
                    ),
                  );
                } else if (state is StandupHistoryLoaded) {
                  if (state.standups.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.standups.length,
                    itemBuilder: (context, index) {
                      final standup = state.standups[index];
                      return _buildStandupCard(standup);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBanner() {
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Row(
        children: [
          const Icon(Icons.filter_list_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đang lọc theo ngày: $dateStr',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _selectDate(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Đổi ngày',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainer,
              shape: BoxShape.circle,
            ),
            child: const Text('📭', style: TextStyle(fontSize: 40)),
          ),
          const SizedBox(height: 16),
          Text(
            'Không có báo cáo nào',
            style: GoogleFonts.plusJakartaSans(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Chưa có thành viên nào ghi Stand-up\ntrong khoảng thời gian này.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStandupCard(StandupModel standup) {
    final timeStr = DateFormat('HH:mm').format(standup.createdAt);
    final dateStr = DateFormat('dd/MM/yyyy').format(standup.createdAt);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.outline.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: User Name + Time
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    standup.userName.isNotEmpty ? standup.userName[0].toUpperCase() : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        standup.userName,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '$timeStr - $dateStr',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (standup.blockers.isNotEmpty && standup.blockers.toLowerCase() != 'không')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🚧', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Text(
                          'Có vướng mắc',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
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
          
          // Body: Answers
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildAnswer('✅', 'Hôm qua', standup.yesterday, const Color(0xFF10B981)),
                const SizedBox(height: 12),
                _buildAnswer('🎯', 'Hôm nay', standup.today, AppColors.primary),
                const SizedBox(height: 12),
                _buildAnswer('🚧', 'Khó khăn', standup.blockers, const Color(0xFFF59E0B)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswer(String emoji, String label, String answer, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                answer.isEmpty ? '(Chưa điền)' : answer,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: AppColors.onSurface,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
