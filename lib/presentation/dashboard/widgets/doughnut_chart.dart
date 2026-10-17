import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../tasks/utils/task_status_style.dart';

/// Biểu đồ Doughnut hiển thị phân bổ tiến độ Sprint (US-065).
///
/// - Vẽ 3 cung: Done, In Progress, To Do bắt đầu từ 12 giờ theo chiều kim đồng hồ.
/// - Có khe hở nhỏ giữa các cung nếu có từ 2 trạng thái trở lên có số lượng > 0.
/// - Khi `total == 0`: vẽ một vòng tròn xám nhạt duy nhất.
/// - Hoạt ảnh vẽ vòng 0 -> 1 trong 600ms qua [TweenAnimationBuilder] (thời lượng 0
///   khi người dùng bật "Giảm chuyển động").
/// - Có [Semantics] mô tả khả năng tiếp cận: "Sprint: X% hoàn thành, a To Do, b In Progress, c Done".
class DoughnutChart extends StatelessWidget {
  final int todo;
  final int inProgress;
  final int done;
  final String? centerTitle;
  final String? centerSubtitle;
  final double size;

  const DoughnutChart({
    super.key,
    required this.todo,
    required this.inProgress,
    required this.done,
    this.centerTitle,
    this.centerSubtitle,
    this.size = 120.0,
  });

  int get total => todo + inProgress + done;

  int get donePercent => total == 0 ? 0 : ((done / total) * 100).round();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 600);

    final doneColor = taskStatusColor(context, 'Done');
    final inProgressColor = taskStatusColor(context, 'In Progress');
    final todoColor = taskStatusColor(context, 'To Do');
    final emptyColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    final semanticsLabel =
        'Sprint: $donePercent% hoàn thành, $todo To Do, $inProgress In Progress, $done Done';

    return Semantics(
      label: semanticsLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: duration,
              curve: Curves.easeOutCubic,
              builder: (context, progress, _) {
                return CustomPaint(
                  size: Size(size, size),
                  painter: _DoughnutPainter(
                    todo: todo,
                    inProgress: inProgress,
                    done: done,
                    animationValue: progress,
                    todoColor: todoColor,
                    inProgressColor: inProgressColor,
                    doneColor: doneColor,
                    emptyColor: emptyColor,
                  ),
                );
              },
            ),
            if (centerTitle != null || centerSubtitle != null)
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (centerTitle != null)
                    Text(
                      centerTitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: size * 0.18,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface,
                        letterSpacing: -0.5,
                      ),
                    ),
                  if (centerSubtitle != null)
                    Text(
                      centerSubtitle!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: size * 0.09,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _DoughnutPainter extends CustomPainter {
  final int todo;
  final int inProgress;
  final int done;
  final double animationValue;
  final Color todoColor;
  final Color inProgressColor;
  final Color doneColor;
  final Color emptyColor;

  static const double _strokeWidthRatio = 0.12;
  static const double _gapAngle = 0.05; // ~3 độ giữa các cung

  _DoughnutPainter({
    required this.todo,
    required this.inProgress,
    required this.done,
    required this.animationValue,
    required this.todoColor,
    required this.inProgressColor,
    required this.doneColor,
    required this.emptyColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * _strokeWidthRatio;
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final total = todo + inProgress + done;

    // Trường hợp không có task nào: vẽ vòng tròn xám nhạt
    if (total == 0) {
      paint.color = emptyColor;
      canvas.drawCircle(center, radius, paint);
      return;
    }

    final segments = <_SegmentData>[];
    if (done > 0) {
      segments.add(_SegmentData(count: done, color: doneColor));
    }
    if (inProgress > 0) {
      segments.add(_SegmentData(count: inProgress, color: inProgressColor));
    }
    if (todo > 0) {
      segments.add(_SegmentData(count: todo, color: todoColor));
    }

    final rect = Rect.fromCircle(center: center, radius: radius);
    final countSegments = segments.length;
    final totalGaps = countSegments > 1 ? countSegments * _gapAngle : 0.0;
    final availableAngle = (2 * pi) - totalGaps;

    // Bắt đầu từ 12 giờ: -pi / 2
    double currentAngle = -pi / 2;

    for (final segment in segments) {
      final sweepAngle = (segment.count / total) * availableAngle * animationValue;
      if (sweepAngle > 0) {
        paint.color = segment.color;
        canvas.drawArc(rect, currentAngle, sweepAngle, false, paint);
      }
      currentAngle += sweepAngle + (countSegments > 1 ? _gapAngle : 0.0);
    }
  }

  @override
  bool shouldRepaint(covariant _DoughnutPainter oldDelegate) {
    return oldDelegate.todo != todo ||
        oldDelegate.inProgress != inProgress ||
        oldDelegate.done != done ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.todoColor != todoColor ||
        oldDelegate.inProgressColor != inProgressColor ||
        oldDelegate.doneColor != doneColor ||
        oldDelegate.emptyColor != emptyColor;
  }
}

class _SegmentData {
  final int count;
  final Color color;

  const _SegmentData({required this.count, required this.color});
}
