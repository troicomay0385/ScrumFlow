import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/ai/risk_prediction_service.dart';
import '../../../data/ai/task_risk_feature_extractor.dart';
import '../../../domain/ai/core/feature_spec.dart';

/// Tiện ích lấy bảng màu chuẩn theo Light/Dark mode cho các thành phần AI.
class AiThemeTokens {
  AiThemeTokens._();

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color cardSurface(BuildContext context) =>
      isDark(context) ? AppColors.darkSurface : AppColors.surface;

  static Color cardSubtleSurface(BuildContext context) => isDark(context)
      ? AppColors.darkSurfaceContainerLow
      : AppColors.surfaceContainerLow;

  static Color border(BuildContext context) =>
      isDark(context) ? AppColors.darkInputBorder : AppColors.inputBorder;

  static Color textPrimary(BuildContext context) =>
      isDark(context) ? AppColors.darkOnSurface : AppColors.onSurface;

  static Color textSecondary(BuildContext context) => isDark(context)
      ? AppColors.darkOnSurfaceVariant
      : AppColors.onSurfaceVariant;

  static Color primary(BuildContext context) =>
      isDark(context) ? AppColors.darkPrimary : AppColors.primaryContainer;

  static Color riskForeground(BuildContext context, RiskLevel level) {
    final dark = isDark(context);
    switch (level) {
      case RiskLevel.low:
        return dark ? AppColors.darkRiskLowFg : AppColors.riskLowFg;
      case RiskLevel.medium:
        return dark ? AppColors.darkRiskMediumFg : AppColors.riskMediumFg;
      case RiskLevel.high:
        return dark ? AppColors.darkRiskHighFg : AppColors.riskHighFg;
    }
  }

  static Color riskBackground(BuildContext context, RiskLevel level) {
    final dark = isDark(context);
    switch (level) {
      case RiskLevel.low:
        return dark ? AppColors.darkRiskLowBg : AppColors.riskLowBg;
      case RiskLevel.medium:
        return dark ? AppColors.darkRiskMediumBg : AppColors.riskMediumBg;
      case RiskLevel.high:
        return dark ? AppColors.darkRiskHighBg : AppColors.riskHighBg;
    }
  }
}

/// Pill hiển thị mức rủi ro trễ hạn của Task (US-069).
///
/// Tuân thủ Design System "Kinetic Sprint" (mục 9 MASTER_PROMPT):
/// - Thấp (<35%): Done (`#047857` trên `#D1FAE5`)
/// - Trung bình (35–65%): In Progress (`#B45309` trên `#FEF3C7`)
/// - Cao (>65%): Blocker (`#B91C1C` trên `#FEE2E2`)
/// - Bo tròn full (`999`), cao tối thiểu 24px, số liệu `%` dùng `JetBrains Mono`.
class RiskBadge extends StatelessWidget {
  final double probability;
  final RiskLevel? levelOverride;
  final bool compact;
  final String? customLabel;

  const RiskBadge({
    super.key,
    required this.probability,
    this.levelOverride,
    this.compact = false,
    this.customLabel,
  });

  factory RiskBadge.fromPrediction({
    Key? key,
    required TaskRiskPrediction prediction,
    bool compact = false,
  }) {
    return RiskBadge(
      key: key,
      probability: prediction.probability,
      levelOverride: prediction.level,
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final level = levelOverride ?? RiskThresholds.classify(probability);
    final fg = AiThemeTokens.riskForeground(context, level);
    final bg = AiThemeTokens.riskBackground(context, level);
    final pct = (probability * 100).round().clamp(0, 100);

    final prefix = compact ? 'RỦI RO' : level.labelVi.toUpperCase();
    final displayText = customLabel ?? '$prefix $pct%';

    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            level == RiskLevel.high
                ? Icons.warning_amber_rounded
                : (level == RiskLevel.medium
                      ? Icons.timelapse_rounded
                      : Icons.verified_outlined),
            size: compact ? 12 : 13,
            color: fg,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              displayText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.jetBrainsMono(
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill trung tính khi Task chưa đặt deadline.
class MissingDeadlineRiskChip extends StatelessWidget {
  const MissingDeadlineRiskChip({super.key});

  @override
  Widget build(BuildContext context) {
    final fg = AiThemeTokens.textSecondary(context);
    final bg = AiThemeTokens.cardSubtleSurface(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 12, color: fg),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'CHƯA ĐẶT DEADLINE',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget hiển thị nhanh RiskBadge từ `TaskRiskPrediction?` trên `TaskCard`.
class TaskCardRiskChip extends StatelessWidget {
  final TaskRiskPrediction? prediction;
  final bool showMissingDeadline;

  const TaskCardRiskChip({
    super.key,
    required this.prediction,
    this.showMissingDeadline = false,
  });

  @override
  Widget build(BuildContext context) {
    final pred = prediction;
    if (pred == null) return const SizedBox.shrink();
    if (!pred.isPredictable) {
      if (showMissingDeadline &&
          pred.skipReason == TaskRiskSkipReason.missingDeadline) {
        return const MissingDeadlineRiskChip();
      }
      return const SizedBox.shrink();
    }
    return RiskBadge.fromPrediction(
      key: Key('task_risk_badge_${pred.task.id}'),
      prediction: pred,
      compact: true,
    );
  }
}
