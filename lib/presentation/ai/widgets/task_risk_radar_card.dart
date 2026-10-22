import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/constants/app_colors.dart';
import '../../../data/ai/task_risk_feature_extractor.dart';
import '../../../domain/ai/core/explainer.dart';
import '../bloc/task_risk_cubit.dart';
import '../bloc/task_risk_state.dart';
import 'risk_badge.dart';
import 'task_what_if_bottom_sheet.dart';

/// Thẻ Bento "AI Risk Radar — Dự báo nguy cơ trễ hạn" hiển thị trong `TaskDetailScreen` (US-069).
///
/// Hiển thị:
/// - Thanh tiến trình xác suất trễ hạn (`0–100%` dùng `JetBrains Mono`) + `RiskBadge`.
/// - Top 3 nhân tố đóng góp lớn nhất (`w_i * z_i`) kèm thanh ngang `+/-` và nhãn tiếng Việt.
/// - Nút mở Bottom Sheet giả lập What-if (đổi người phụ trách / gia hạn deadline).
class TaskRiskRadarCard extends StatelessWidget {
  final VoidCallback? onRetry;
  final bool canApplyWhatIf;
  final Future<void> Function(String? newAssigneeId, DateTime? newDeadline)?
  onApplyWhatIf;

  const TaskRiskRadarCard({
    super.key,
    this.onRetry,
    this.canApplyWhatIf = true,
    this.onApplyWhatIf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('task_risk_radar_card'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AiThemeTokens.cardSurface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AiThemeTokens.border(context)),
      ),
      child: BlocBuilder<TaskRiskCubit, TaskRiskState>(
        builder: (context, state) {
          if (state.status == TaskRiskStatus.initial ||
              state.status == TaskRiskStatus.loading) {
            return _buildLoading(context);
          }

          if (state.status == TaskRiskStatus.error) {
            return _buildError(context, state.errorMessage);
          }

          final prediction = state.prediction;
          if (prediction == null) {
            return _buildError(context, 'Chưa có dữ liệu dự báo.');
          }

          if (prediction.skipReason == TaskRiskSkipReason.alreadyDone) {
            return _buildSkippedDone(context);
          }

          if (prediction.skipReason == TaskRiskSkipReason.missingDeadline) {
            return _buildSkippedNoDeadline(context);
          }

          final pct = prediction.probabilityPercent;
          final fgColor = AiThemeTokens.riskForeground(
            context,
            prediction.level,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AiThemeTokens.primary(
                        context,
                      ).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.radar_rounded,
                      size: 18,
                      color: AiThemeTokens.primary(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Risk Radar',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AiThemeTokens.textPrimary(context),
                          ),
                        ),
                        Text(
                          'Dự báo nguy cơ trễ hạn cục bộ (Logistic Regression)',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AiThemeTokens.textSecondary(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: RiskBadge.fromPrediction(
                      key: const Key('task_detail_risk_badge'),
                      prediction: prediction,
                      compact: MediaQuery.sizeOf(context).width < 360,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Thanh tiến trình xác suất
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Xác suất trễ hạn dự báo',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AiThemeTokens.textSecondary(context),
                      ),
                    ),
                  ),
                  Text(
                    '$pct%',
                    key: const Key('task_risk_probability_text'),
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: fgColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: prediction.probability.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AiThemeTokens.cardSubtleSurface(context),
                  valueColor: AlwaysStoppedAnimation<Color>(fgColor),
                ),
              ),
              const SizedBox(height: 14),

              // Top 3 yếu tố đóng góp
              Text(
                '3 yếu tố ảnh hưởng lớn nhất:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AiThemeTokens.textPrimary(context),
                ),
              ),
              const SizedBox(height: 8),
              ...prediction.topReasons.map(
                (contrib) => _ContributionRow(contribution: contrib),
              ),

              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  key: const Key('task_risk_open_what_if_button'),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AiThemeTokens.primary(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final cubit = context.read<TaskRiskCubit>();
                    showTaskWhatIfBottomSheet(
                      context: context,
                      cubit: cubit,
                      canApplyChanges: canApplyWhatIf,
                      onApply: onApplyWhatIf,
                    );
                  },
                  icon: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: AiThemeTokens.primary(context),
                  ),
                  label: Text(
                    'Xem giả lập (What-if)',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AiThemeTokens.primary(context),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AiThemeTokens.primary(context),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Đang phân tích rủi ro trễ hạn bằng mô hình AI...',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AiThemeTokens.textSecondary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, String? message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message ?? 'Không thể phân tích rủi ro.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AiThemeTokens.textPrimary(context),
                ),
              ),
            ),
          ],
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 8),
          TextButton.icon(
            key: const Key('task_risk_retry_button'),
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Thử lại'),
          ),
        ],
      ],
    );
  }

  Widget _buildSkippedNoDeadline(BuildContext context) {
    return Row(
      key: const Key('task_risk_missing_deadline_view'),
      children: [
        Icon(
          Icons.event_busy_rounded,
          color: AiThemeTokens.textSecondary(context),
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Risk Radar · Chưa đặt deadline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AiThemeTokens.textPrimary(context),
                ),
              ),
              Text(
                'Hãy đặt hạn hoàn thành (Deadline) cho Task để AI dự báo xác suất trễ hạn.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AiThemeTokens.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkippedDone(BuildContext context) {
    return Row(
      key: const Key('task_risk_already_done_view'),
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: AppColors.success,
          size: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Task đã hoàn thành (Done) — không còn nguy cơ trễ hạn.',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AiThemeTokens.textPrimary(context),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContributionRow extends StatelessWidget {
  final FeatureContribution contribution;

  const _ContributionRow({required this.contribution});

  @override
  Widget build(BuildContext context) {
    final isIncreasingRisk = contribution.increasesRisk;
    final barColor = isIncreasingRisk ? AppColors.error : AppColors.success;
    final barRatio = min(1.0, contribution.magnitude / 1.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isIncreasingRisk
                    ? Icons.trending_up_rounded
                    : Icons.trending_down_rounded,
                size: 14,
                color: barColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  contribution.labelVi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AiThemeTokens.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                contribution.formattedPercentPoints,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: barColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: barRatio,
              minHeight: 5,
              backgroundColor: AiThemeTokens.cardSubtleSurface(context),
              valueColor: AlwaysStoppedAnimation<Color>(barColor),
            ),
          ),
        ],
      ),
    );
  }
}
