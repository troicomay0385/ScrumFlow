import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/models/sprint_model.dart';
import '../../../data/models/user_story_model.dart';

/// Dữ liệu biểu đồ Burndown Chart (US-025).
class BurndownData {
  final int totalDays;
  final int currentDayIndex; // 0-based
  final int totalStoryPoints;
  final int remainingStoryPoints;
  final int completedStoryPoints;
  final List<double> idealPoints;
  final List<double?> actualPoints; // null cho những ngày trong tương lai
  final List<String> dayLabels;

  const BurndownData({
    required this.totalDays,
    required this.currentDayIndex,
    required this.totalStoryPoints,
    required this.remainingStoryPoints,
    required this.completedStoryPoints,
    required this.idealPoints,
    required this.actualPoints,
    required this.dayLabels,
  });

  factory BurndownData.calculate({
    required SprintModel sprint,
    required List<UserStoryModel> stories,
  }) {
    final start = sprint.startDate;
    final end = sprint.endDate;
    final now = DateTime.now();

    final daysDiff = end.difference(start).inDays;
    final totalDays = max(1, daysDiff + 1);

    // Tính tổng Story Points
    final totalPoints = stories.fold<int>(
      0,
      (sum, s) => sum + (s.storyPoints > 0 ? s.storyPoints : 1),
    );

    // Điểm đã hoàn thành hiện tại
    final doneStories = stories.where((s) => s.status == 'Done').toList();
    final completedPoints = doneStories.fold<int>(
      0,
      (sum, s) => sum + (s.storyPoints > 0 ? s.storyPoints : 1),
    );
    final remainingPoints = max(0, totalPoints - completedPoints);

    // Ngày hiện tại (chặn từ 0 đến totalDays - 1)
    int currentDayIdx = now.difference(start).inDays;
    if (currentDayIdx < 0) currentDayIdx = 0;
    if (currentDayIdx >= totalDays) currentDayIdx = totalDays - 1;

    final ideal = <double>[];
    final actual = <double?>[];
    final labels = <String>[];

    for (int i = 0; i < totalDays; i++) {
      final date = start.add(Duration(days: i));
      labels.add('${date.day}/${date.month}');

      // Đường lý tưởng: từ totalPoints giảm về 0
      final idealValue = totalPoints - (totalPoints / (totalDays - 1 > 0 ? totalDays - 1 : 1)) * i;
      ideal.add(max(0.0, idealValue));

      if (i <= currentDayIdx) {
        // Tính điểm hoàn thành tính tới ngày đó
        int doneUpToDay = 0;
        for (final s in doneStories) {
          if (s.updatedAt.isBefore(date.add(const Duration(days: 1)))) {
            doneUpToDay += (s.storyPoints > 0 ? s.storyPoints : 1);
          }
        }
        actual.add(max(0.0, (totalPoints - doneUpToDay).toDouble()));
      } else {
        actual.add(null);
      }
    }

    return BurndownData(
      totalDays: totalDays,
      currentDayIndex: currentDayIdx,
      totalStoryPoints: totalPoints,
      remainingStoryPoints: remainingPoints,
      completedStoryPoints: completedPoints,
      idealPoints: ideal,
      actualPoints: actual,
      dayLabels: labels,
    );
  }
}

/// Widget hiển thị Burndown Chart phong cách Kinetic Sprint Bento (US-025).
class BurndownChartWidget extends StatelessWidget {
  final SprintModel sprint;
  final List<UserStoryModel> stories;

  const BurndownChartWidget({
    super.key,
    required this.sprint,
    required this.stories,
  });

  @override
  Widget build(BuildContext context) {
    final data = BurndownData.calculate(sprint: sprint, stories: stories);

    // Đánh giá tiến độ
    final currentActual = data.actualPoints[data.currentDayIndex] ?? data.totalStoryPoints.toDouble();
    final currentIdeal = data.idealPoints[data.currentDayIndex];
    final isOnTrack = currentActual <= currentIdeal + 1.0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.outline.withValues(alpha: 0.12)),
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
          // 1. Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.show_chart_rounded, size: 20, color: AppColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Burndown Chart',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.onSurface,
                      ),
                    ),
                    Text(
                      'Biểu đồ tiến độ công việc còn lại theo ngày',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isOnTrack ? AppColors.success : AppColors.warning).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isOnTrack ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  isOnTrack ? 'Đúng tiến độ' : 'Chậm tiến độ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isOnTrack ? AppColors.success : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Summary stats mini
          Row(
            children: [
              _buildStatPill('Khối lượng ban đầu', '${data.totalStoryPoints} SP', AppColors.onSurface),
              const SizedBox(width: 8),
              _buildStatPill('Đã xong', '${data.completedStoryPoints} SP', AppColors.success),
              const SizedBox(width: 8),
              _buildStatPill('Còn lại', '${data.remainingStoryPoints} SP', const Color(0xFF6366F1)),
            ],
          ),
          const SizedBox(height: 20),

          // 3. CustomPainter Canvas
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(
              painter: _BurndownPainter(data: data),
            ),
          ),
          const SizedBox(height: 16),

          // 4. Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: const Color(0xFF94A3B8),
                isDashed: true,
                label: 'Tiến độ lý tưởng (Ideal)',
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                color: const Color(0xFF6366F1),
                isDashed: false,
                label: 'Thực tế còn lại (Actual)',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required bool isDashed,
    required String label,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

/// CustomPainter vẽ đồ thị đường Burndown Chart
class _BurndownPainter extends CustomPainter {
  final BurndownData data;

  _BurndownPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const double paddingLeft = 32.0;
    const double paddingRight = 16.0;
    const double paddingTop = 12.0;
    const double paddingBottom = 24.0;

    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingTop - paddingBottom;

    final maxPoints = data.totalStoryPoints > 0 ? data.totalStoryPoints.toDouble() : 10.0;
    final totalDays = data.totalDays;

    // 1. Grid lines và Trục Y labels
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0;

    final textStyle = GoogleFonts.inter(
      fontSize: 10,
      color: const Color(0xFF94A3B8),
    );

    const int gridRows = 3;
    for (int i = 0; i <= gridRows; i++) {
      final y = paddingTop + (chartHeight / gridRows) * i;
      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(paddingLeft + chartWidth, y),
        gridPaint,
      );

      final val = (maxPoints - (maxPoints / gridRows) * i).round();
      final tp = TextPainter(
        text: TextSpan(text: '$val', style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - tp.height / 2));
    }

    // 2. Trục X labels (Điểm đầu, giữa, cuối)
    final labelIndices = [0, totalDays ~/ 2, totalDays - 1];
    for (final idx in labelIndices) {
      if (idx >= 0 && idx < data.dayLabels.length) {
        final x = paddingLeft + (chartWidth / (totalDays - 1 > 0 ? totalDays - 1 : 1)) * idx;
        final tp = TextPainter(
          text: TextSpan(text: data.dayLabels[idx], style: textStyle),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, size.height - paddingBottom + 6));
      }
    }

    // 3. Đường Lý Tưởng (Ideal Line - Nét đứt màu xám xanh)
    final idealPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final idealPath = Path();
    for (int i = 0; i < totalDays; i++) {
      final x = paddingLeft + (chartWidth / (totalDays - 1 > 0 ? totalDays - 1 : 1)) * i;
      final y = paddingTop + chartHeight - (data.idealPoints[i] / maxPoints) * chartHeight;
      if (i == 0) {
        idealPath.moveTo(x, y);
      } else {
        idealPath.lineTo(x, y);
      }
    }
    canvas.drawPath(idealPath, idealPaint);

    // 4. Đường Thực Tế (Actual Line - Gradient Tím đậm & Gradient Fill)
    final actualPointsList = <Offset>[];
    for (int i = 0; i < totalDays; i++) {
      final val = data.actualPoints[i];
      if (val != null) {
        final x = paddingLeft + (chartWidth / (totalDays - 1 > 0 ? totalDays - 1 : 1)) * i;
        final y = paddingTop + chartHeight - (val / maxPoints) * chartHeight;
        actualPointsList.add(Offset(x, y));
      }
    }

    if (actualPointsList.isNotEmpty) {
      // Vùng đổ bóng bên dưới đường thực tế
      final fillPath = Path()..moveTo(actualPointsList.first.dx, paddingTop + chartHeight);
      for (final pt in actualPointsList) {
        fillPath.lineTo(pt.dx, pt.dy);
      }
      fillPath.lineTo(actualPointsList.last.dx, paddingTop + chartHeight);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            const Color(0xFF6366F1).withValues(alpha: 0.25),
            const Color(0xFF6366F1).withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(paddingLeft, paddingTop, chartWidth, chartHeight));
      canvas.drawPath(fillPath, fillPaint);

      // Nét vẽ thực tế
      final actualLinePaint = Paint()
        ..color = const Color(0xFF4F46E5)
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final actualPath = Path()..moveTo(actualPointsList.first.dx, actualPointsList.first.dy);
      for (int i = 1; i < actualPointsList.length; i++) {
        actualPath.lineTo(actualPointsList[i].dx, actualPointsList[i].dy);
      }
      canvas.drawPath(actualPath, actualLinePaint);

      // Điểm mốc tròn
      final dotPaint = Paint()..color = const Color(0xFF4F46E5);
      final whitePaint = Paint()..color = Colors.white;

      for (final pt in actualPointsList) {
        canvas.drawCircle(pt, 5.0, dotPaint);
        canvas.drawCircle(pt, 2.5, whitePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BurndownPainter oldDelegate) => true;
}
